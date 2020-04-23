package service

import (
	"errors"

	"github.com/pwnlandia/mhn/auth"
	"github.com/pwnlandia/mhn/config"
	"github.com/pwnlandia/mhn/model"
	"github.com/pwnlandia/mhn/user"
)

// ErrSuperAdminExists means a new SA cannot be created.
var ErrSuperAdminExists = errors.New("super admin already exists")

// configService is our app implementation of config.Service
type configService struct {
	repo        config.Repository
	userService user.Service
}

// NewConfigService returns a new instance of a configService initialized with the
// given repository.
func NewConfigService(repo config.Repository, us user.Service) config.Service {
	return &configService{repo, us}
}

// JWTSecret provides the current JSON Web Token signing secret in use in the config.
func (s *configService) JWTSecret() (*auth.JWTSecret, error) {
	return s.repo.JWTSecret()
}

// SuperAdmin provides the current SuperAdmin account username set in the config.
func (s *configService) SuperAdmin() (string, error) {
	return s.repo.SuperAdmin()
}

// SetJWTSecret will first make sure the provided secret is valid and then set
// it to the config.
func (s *configService) SetJWTSecret(secret []byte) error {
	// TODO: Make sure secret is valid here.
	return s.repo.SetJWTSecret(secret)
}

// CreateSuperAdmin will take a username, generate a new password, and save this
// user with SuperAdmin permissions.
// TODO: Refactor so we don't return a full user and pass?
func (s *configService) CreateSuperAdmin(name string) (*model.User, string, error) {
	sa, err := s.repo.SuperAdmin()
	if err != nil {
		return nil, "", err
	}
	if sa != "" {
		return nil, "", ErrSuperAdminExists
	}

	p := auth.NewPassword()

	u, err := model.NewUser(name, p, auth.RoleSuperAdmin)
	if err != nil {
		return nil, "", err
	}

	err = s.userService.SaveUser(u)
	if err != nil {
		return nil, "", err
	}

	// TODO: If SetSA fails, User will still exist.
	err = s.repo.SetSuperAdmin(name)
	return u, p, err
}

// ResetSuperAdmin will delete the currently stored username for Super Admin,
// which allows a new Super Admin to be initialized.
func (s *configService) ResetSuperAdmin() error {
	return s.repo.SetSuperAdmin("")
}
