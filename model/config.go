package model

import "github.com/pwnlandia/mhn/auth"

// Config holds all the necessary application level configuration items.
type Config struct {
	// If JWTSecret is ever invalid, we generate a new one randomly.
	JWTSecret *auth.JWTSecret
	// SuperAdmin is the username of the SA account. If this is "" we allow
	// generation of a new one from the superadmin endpoint. (first time running)
	SuperAdmin string
}
