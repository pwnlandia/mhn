from math import ceil

from flask import jsonify, g

from mhn.constants import PAGE_SIZE


def error_response(message, status_code=400):
    resp = jsonify({'error': message})
    resp.status_code = status_code
    return resp


def alchemy_pages(query, **kwargs):
    page = kwargs.get('page', g.page)
    page_size = kwargs.get('limit', PAGE_SIZE)
    items = query.\
            offset((page - 1) * page_size).\
            limit(page_size)
    return Pagination(page, page_size, query.count(), items)


def mongo_pages(result, total, **kwargs):
    page_size = kwargs.get('limit', PAGE_SIZE)
    return Pagination(g.page, page_size, total, result)


def paginate_options(**kwargs):
    page = kwargs.get('page', g.page)
    page_size = kwargs.get('limit', PAGE_SIZE)
    return dict(skip=(page - 1) * page_size, limit=page_size)


class Pagination(object):
    """
    This Pagination class will work with both SQLAlchemy
    objects and Clio objects.
    Taken and stripped from Flask-SQLAlchemy"""

    def __init__(self, page, per_page, total, items):
        #: the current page number (1 indexed)
        self.page = page
        #: the number of items to be displayed on a page.
        self.per_page = per_page
        #: the total number of items matching the query
        self.total = total
        #: the items for the current page
        self.items = items

    @property
    def pages(self):
        """The total number of pages"""
        if self.per_page == 0:
            pages = 0
        else:
            pages = int(ceil(self.total / float(self.per_page)))
        return pages

    @property
    def prev_num(self):
        """Number of the previous page."""
        return self.page - 1

    @property
    def has_prev(self):
        """True if a previous page exists"""
        return self.page > 1

    @property
    def has_next(self):
        """True if a next page exists."""
        return self.page < self.pages

    @property
    def next_num(self):
        """Number of the next page"""
        return self.page + 1

    def iter_pages(self, left_edge=2, left_current=2,
                   right_current=5, right_edge=2):
        last = 0
        for num in xrange(1, self.pages + 1):
            if num <= left_edge or \
               (num > self.page - left_current - 1 and \
                num < self.page + right_current) or \
               num > self.pages - right_edge:
                if last + 1 != num:
                    yield None
                yield num
                last = num
