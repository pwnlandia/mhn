package user

import (
	"errors"

	"github.com/pwnlandia/mhn/model"
)

var (
	// ErrUserNotFound means the user name was not found in the repo
	ErrUserNotFound = errors.New("user not found")

	// ErrUserExists is returned if a create is called on an existing user
	ErrUserExists = errors.New("user with that name exists")
)

// Service provides an interface for all business operations on the User model.
type Service interface {
	GetAllUsers() ([]*model.User, error)
	GetUser(name string) (*model.User, error)
	SaveUser(u *model.User) error
	DeleteUser(name string) error
	DeleteAllUsers() error
}
