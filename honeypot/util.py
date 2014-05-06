import pickle

def safe_unpickle(dfile):
    try:
        return pickle.load(open(dfile, 'r'))
    except IOError:
        return None

def safe_pickle(dfile, date):
    pickle.dump(date, open(dfile, 'w'))
