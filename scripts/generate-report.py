from __future__ import unicode_literals
import json
import requests
import logging
import time
import datetime
import dateutil.parser
import matplotlib.pyplot as plt
import numpy as np
from io import open
from string import Template
from jinja2 import Environment, FileSystemLoader
from weasyprint import HTML
from PIL import Image

api_token = "your_api_token_goes_here"
server_url = "server_ip_or_name"
api_url_base = 'https://github.com/threatstream/mhn/wiki/MHN-REST-APIs'
headers = {'Content-Type': 'application/json',
		   'Authorization': 'Bearer {0}'.format(api_token)}
html_string = " "


def http_response_check(responseCode,api_url):

	if responseCode >= 500:
		logging.error ('{0} - [!] [{1}] Server Error: [{2}]'.format(datetime.datetime.now(),responseCode,api_url))
	elif responseCode == 404:
		logging.error ('{0} - [!] [{1}] URL not found: [{2}]'.format(datetime.datetime.now(),responseCode,api_url))
	elif responseCode == 401:
		logging.error ('{0} - [!] [{1}] Authentication Failed: [{2}]'.format(datetime.datetime.now(),responseCode,api_url))
	elif responseCode == 400:
		logging.error ('{0} - [!] [{1}] Bad Request: [{2}]'.format(datetime.datetime.now(),responseCode,api_url))
	elif responseCode >= 300:
		logging.error ('{0} - [!] [{1}] Unexpected Redirect: [{2}]'.format(datetime.datetime.now(),responseCode,api_url))
	elif responseCode == 200:
		logging.debug('{0} - Data retrived successfully: [{1}]'.format(datetime.datetime.now(),api_url))
		return 200
	else:
		logging.error ('{0} - [?] Unexpected Error: [HTTP {1}]: URL: {2}'.format(datetime.datetime.now(),responseCode,api_url))
	return None

def get_top_attackers():

	global html_string
	api_url = 'http://{0}/api/top_attackers/?api_key={1}&hours_ago=168'.format(server_url,api_token)
	response = requests.get(api_url, headers=headers)
	http_code = http_response_check(response.status_code,api_url)
	if http_code == 200:
		top_attackers = json.loads(response.content.decode('utf-8'))
		source = []
		honeypot_raw_data = []
		count = []
		html_string = '<h2><span style="color: #008cba;">Attacker metadata</span></h2>'
		html_string += "<ol>"
		for key, details in enumerate(top_attackers['data']):
			for k, v in details.items():
				if (k == "count"):
					count.append(v)
				elif (k == "honeypot"):
					honeypot_raw_data.append(v.encode('utf-8'))
				elif (k == "source_ip"):
					source.append(v.encode('utf-8'))
					html_string += "<br/><br/>"
					html_string += "<b><li>{0}</b></li>".format(v.encode('utf-8'))
					get_attacker_metdata(v.encode('utf-8'))
					get_attacker_stats(v.encode('utf-8'))
		html_string += "</ol>"
		figure1 = generate_plot(count,source,"Attacks","Attacker Statistics")
		figure1.savefig('top-attackers-ip.png')
		i = iter(honeypot_raw_data)
		j = iter(count)
		k = list(zip(i, j))
		d = {}
		for (x,y) in k:
			if x in d:
				d[x] = d[x] + y
			else:
				d[x] = y
		honeypot_data = d.keys()
		honeypot_count = d.values()
		figure2 = generate_plot(honeypot_count,honeypot_data,'Attacks','Sensor Statistics')
		figure2.savefig('top-attackers-honeypot.png')
	else:
		return None

def generate_plot(datameasure,datasource,xlabel,title):

	figure, ax = plt.subplots()
	y_pos = np.arange(len(datameasure))
	ax.barh(y_pos, datameasure, align='center')
	ax.set_yticks(y_pos)
	ax.set_yticklabels(datasource,fontsize=7,rotation=30)
	ax.set_xlabel(xlabel)
	ax.set_title(title)
	return figure

def get_attacker_metdata(source_ip):

	global html_string
	api_url = 'http://{0}/api/metadata/?api_key={1}&ip={2}'.format(server_url,api_token,source_ip)
	response = requests.get(api_url, headers=headers)
	http_code = http_response_check(response.status_code,api_url)
	if response.status_code == 200:
		metadata = json.loads(response.content.decode('utf-8'))
		for key, details in enumerate(metadata['data']):
				for key, value in details.items():
					if (key == "os"):
						if (value != None):
							html_string += "<b>OS detected:</b> {0}".format(value.encode('utf-8'))
							html_string += "<br/>"
	else:
		return None

def get_attacker_stats(source_ip):

	global html_string
	api_url =  'http://{0}/api/attacker_stats/{1}/?api_key={2}'.format(server_url,source_ip,api_token)
	response = requests.get(api_url, headers=headers)
	http_code = http_response_check(response.status_code,api_url)
	if http_code == 200:
		attacker_stats = json.loads(response.content.decode('utf-8'))
		attacker_counter = attacker_stats['data']['count']
		html_string += "<b>Total attacks made:</b> {0}".format(attacker_counter)
		first_seen = attacker_stats['data']['first_seen']
		first_seen_readable = dateutil.parser.parse(first_seen)
		html_string += "<br/><b>First Seen on:</b> {:%d %B %Y %I:%M:%S %p}".format(first_seen_readable)
		last_seen = attacker_stats['data']['last_seen']
		last_seen_readable = dateutil.parser.parse(last_seen)
		html_string += "<br/><b>Last Seen on:</b> {:%d %B %Y %I:%M:%S %p}".format(last_seen_readable)
		attacker_honeypots = attacker_stats['data']['honeypots']
		if attacker_honeypots:
			html_string += "<br/><b>Sensors Attacked:</b>"
			for k in attacker_honeypots:
				html_string += " {0} ".format(k.encode('utf-8'))
		attacker_ports = attacker_stats['data']['ports']
		if attacker_ports:
			html_string += "<br/><b>Ports Attacked:</b>"
			for k in attacker_ports:
				html_string += " {0} ".format(k)
	else:
		return None

if __name__ == "__main__":
	try:
		logging.basicConfig(filename='mhn-report.log', level=logging.DEBUG)
		top_attackers = get_top_attackers()
		env = Environment(loader=FileSystemLoader('.'))
		template = env.get_template("report-template.html")
		template_vars = {"generated_date" : datetime.datetime.now().strftime('%I:%M:%S %p %A, %B the %dth, %Y'),
						 "generated_source": server_url,
						 "top_attackers_ip_plot": "file:top-attackers-ip.png",
						 "top_attackers_honeypot_plot": "file:top-attackers-honeypot.png"}
		html_out = template.render(template_vars)
		html_out = html_out + html_string
		#print html_out
		filename = "report-mhn-{0}.pdf".format(datetime.datetime.now().strftime('%Y-%m-%d'))
		HTML(string=html_out).write_pdf(filename)
		send_mail()
	except Exception, e:
		logging.error("{0} - Error: Unknown error, program terminated".format(datetime.datetime.now()))
