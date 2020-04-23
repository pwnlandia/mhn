package config

import (
	"github.com/pwnlandia/mhn/auth"
	"github.com/pwnlandia/mhn/model"
)

// Service provides an interface for manipulating configs.
type Service interface {
	JWTSecret() (*auth.JWTSecret, error)
	SuperAdmin() (string, error)
	SetJWTSecret([]byte) error
	CreateSuperAdmin(string) (user *model.User, password string, err error)
	ResetSuperAdmin() error
}
