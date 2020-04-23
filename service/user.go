package service

import (
	"github.com/pwnlandia/mhn/model"
	"github.com/pwnlandia/mhn/user"
)

type userService struct {
	repo user.Repository
}

// NewUserService returns a new instance of a userService initialized with the
// given repository.
func NewUserService(repo user.Repository) user.Service {
	return userService{repo}
}

// GetAllUsers returns a slice of pointers to all users stored in the repo.
func (us userService) GetAllUsers() ([]*model.User, error) {
	return us.repo.GetAllUsers()
}

// GetUser returns a pointer to the User with a matching name. If none is found,
// an error is returned and the user is nil.
func (us userService) GetUser(name string) (*model.User, error) {
	return us.repo.GetUser(name)
}

// SaveUser simply saves a user to the repo.
// TODO: Add sanity checks here
func (us userService) SaveUser(u *model.User) error {
	return us.repo.SaveUser(u)
}

// DeleteUser deletes all the specified user in the repository.
func (us userService) DeleteUser(name string) error {
	return us.repo.DeleteUser(name)
}

// DeleteAllUsers deletes all users in the repository.
func (us userService) DeleteAllUsers() error {
	return us.repo.DeleteAllUsers()
}
