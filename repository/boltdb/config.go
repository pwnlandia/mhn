package boltdb

import (
	"fmt"

	"github.com/boltdb/bolt"
	"github.com/pwnlandia/mhn/auth"
	"github.com/pwnlandia/mhn/config"
)

const (
	configBucket = "config"

	jwtSecretKey  = "jwtsecret"
	superAdminKey = "superadmin"
)

var configBuckets = []string{
	configBucket,
}

type configRepository struct {
	*bolt.DB
}

// NewConfigRepository provides a new ConfigRepo powered by BoltDB.
func NewConfigRepository(db *bolt.DB) (config.Repository, error) {
	err := db.Update(func(tx *bolt.Tx) error {
		for _, b := range configBuckets {
			_, err := tx.CreateBucketIfNotExists([]byte(b))
			if err != nil {
				return fmt.Errorf("create bucket: %s", err)
			}
		}
		return nil
	})
	return &configRepository{db}, err
}

// JWTSecret returns the currently stored JWT signing secret from boltdb.
func (r *configRepository) JWTSecret() (*auth.JWTSecret, error) {
	var secret auth.JWTSecret
	err := r.DB.View(func(tx *bolt.Tx) error {
		b := tx.Bucket([]byte(configBucket))
		v := b.Get([]byte(jwtSecretKey))

		secret.SetSecret(v)
		return nil
	})
	return &secret, err
}

// SetJWTSecret stores the given secret in boltdb.
func (r *configRepository) SetJWTSecret(secret []byte) error {
	err := r.DB.Update(func(tx *bolt.Tx) error {
		b := tx.Bucket([]byte(configBucket))
		b.Put([]byte(jwtSecretKey), secret)
		return nil
	})
	return err
}

// SuperAdmin returns the currently stored super admin username from boltdb.
func (r *configRepository) SuperAdmin() (string, error) {
	var name string
	err := r.DB.View(func(tx *bolt.Tx) error {
		b := tx.Bucket([]byte(configBucket))
		v := b.Get([]byte(superAdminKey))
		if v == nil {
			return nil
		}
		name = string(v)
		return nil
	})
	return name, err
}

// SetSuperAdmin stores the given username in boltdb.
func (r *configRepository) SetSuperAdmin(name string) error {
	err := r.DB.Update(func(tx *bolt.Tx) error {
		b := tx.Bucket([]byte(configBucket))
		b.Put([]byte(superAdminKey), []byte(name))
		return nil
	})
	return err
}
