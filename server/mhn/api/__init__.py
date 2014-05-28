class APIModel(object):
    @classmethod
    def fields(cls):
        return cls.all_fields.keys()

    @classmethod
    def editable_fields(cls):
        return cls._make_field_list('editable')

    @classmethod
    def required_fields(cls):
        return cls._make_field_list('required')

    @classmethod
    def _make_field_list(cls, prop):
        """
        Returns a list of field names that have the property
        `prop` in the `all_fields` dictionary defined at
        class level.
        """
        return [f for f, e in cls.all_fields.items() if e.get(prop, False)]

    @classmethod
    def check_required(cls, payload):
        """
        Returns a list of required fields that are
        missing from the dictionary object `payload`.
        """
        missing = []
        for field in cls.required_fields():
            if (field not in payload) or payload.get(field) == '':
                missing.append(field)
        return missing

