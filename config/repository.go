package config

import "github.com/pwnlandia/mhn/auth"

// Repository provides an interface for persisting config options.
type Repository interface {
	JWTSecret() (*auth.JWTSecret, error)
	SuperAdmin() (string, error)
	SetJWTSecret([]byte) error
	SetSuperAdmin(string) error
}
