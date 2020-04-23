package model

import (
	"github.com/alexedwards/argon2id"
)

// User is a system user for the webapp.
type User struct {
	Name string
	Role string // RBAC role

	Hash string // Will always be an encoding of a password hash
}

// NewUser creates a user object with a hashed version of the passed in
// password.
func NewUser(name, password, role string) (*User, error) {
	hash, err := argon2id.CreateHash(password, argon2id.DefaultParams)
	if err != nil {
		return nil, err
	}
	return &User{Name: name, Hash: hash, Role: role}, nil
}

// ComparePasswordAndHash takes a password as input, and compares the password hashes to
// determine if they should be authenticated.
func (u User) ComparePasswordAndHash(password string) (bool, error) {
	match, err := argon2id.ComparePasswordAndHash(password, u.Hash)
	return match, err
}

// SetPassword takes a plaintext password and stores the hash of it in the
// object.
func (u *User) SetPassword(password string) error {
	hash, err := argon2id.CreateHash(password, argon2id.DefaultParams)
	if err != nil {
		return err
	}
	u.Hash = hash
	return nil
}
