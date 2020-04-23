package boltdb

import (
	"encoding/json"
	"fmt"

	"github.com/boltdb/bolt"
	"github.com/pwnlandia/mhn/model"
	"github.com/pwnlandia/mhn/user"
)

var userBucket = []byte("users")

var userBuckets = []string{
	string(userBucket),
}

type userRepository struct {
	*bolt.DB
}

// NewUserRepository returns a new repo object with the associate bolt.DB
func NewUserRepository(db *bolt.DB) (user.Repository, error) {
	err := db.Update(func(tx *bolt.Tx) error {
		for _, b := range userBuckets {
			_, err := tx.CreateBucketIfNotExists([]byte(b))
			if err != nil {
				return fmt.Errorf("create bucket: %s", err)
			}
		}
		return nil
	})
	return &userRepository{db}, err
}

// GetAllUsers returns a list of all user objects stored in the
// db.
func (ur *userRepository) GetAllUsers() ([]*model.User, error) {
	var users []*model.User
	err := ur.DB.View(func(tx *bolt.Tx) error {
		b := tx.Bucket(userBucket)

		c := b.Cursor()

		for k, v := c.First(); k != nil; k, v = c.Next() {
			u := &model.User{}
			err := json.Unmarshal(v, &u)
			if err != nil {
				return err
			}

			users = append(users, u)
		}

		return nil
	})
	return users, err
}

// GetUser takes an username and returns their whole user object.
func (ur *userRepository) GetUser(name string) (*model.User, error) {
	var u *model.User
	err := ur.DB.View(func(tx *bolt.Tx) error {
		b := tx.Bucket(userBucket)
		v := b.Get([]byte(name))
		if v == nil {
			return nil
		}
		u = &model.User{}
		err := json.Unmarshal(v, &u)
		return err
	})
	return u, err
}

// SaveUser persists a User in BoltStore.
func (ur *userRepository) SaveUser(u *model.User) error {
	err := ur.DB.Update(func(tx *bolt.Tx) error {
		b := tx.Bucket(userBucket)
		buf, err := json.Marshal(u)
		b.Put([]byte(u.Name), buf)
		return err
	})
	return err
}

// DeleteUser removes any saved User object matching the username
func (ur *userRepository) DeleteUser(name string) error {
	err := ur.DB.Update(func(tx *bolt.Tx) error {
		b := tx.Bucket(userBucket)
		b.Delete([]byte(name))
		return nil
	})
	return err
}

// DeleteAllUsers deletes the Bolt bucket holding users and recreates
// it, essentially deleting all objects.
func (ur *userRepository) DeleteAllUsers() error {
	err := ur.DB.Update(func(tx *bolt.Tx) error {
		err := tx.DeleteBucket(userBucket)
		if err != nil {
			return err
		}
		_, err = tx.CreateBucket(userBucket)
		if err != nil {
			return err
		}

		return nil
	})
	return err
}
