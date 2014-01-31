from mhn.auth import current_user


def user_ctx():
    """
    Inserts current user templates context.
    """
    return dict(user=current_user)
