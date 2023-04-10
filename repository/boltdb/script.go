package boltdb

import (
	"encoding/json"
	"fmt"

	"github.com/boltdb/bolt"
	"github.com/pwnlandia/mhn/model"
	"github.com/pwnlandia/mhn/script"
)

var scriptBucket = []byte("scripts")

var scriptBuckets = []string{
	string(scriptBucket),
}

type scriptRepository struct {
	*bolt.DB
}

// NewScriptRepository returns a new repo object with the associate bolt.DB
func NewScriptRepository(db *bolt.DB) (script.Repository, error) {
	err := db.Update(func(tx *bolt.Tx) error {
		for _, b := range scriptBuckets {
			_, err := tx.CreateBucketIfNotExists([]byte(b))
			if err != nil {
				return fmt.Errorf("create bucket: %s", err)
			}
		}
		return nil
	})
	return &scriptRepository{db}, err
}

// GetAllScripts returns a list of all script objects stored in the
// db.
func (sr *scriptRepository) GetAllScripts() ([]*model.Script, error) {
	var scripts []*model.Script
	err := sr.DB.View(func(tx *bolt.Tx) error {
		b := tx.Bucket(scriptBucket)

		c := b.Cursor()

		for k, v := c.First(); k != nil; k, v = c.Next() {
			s := &model.Script{}
			err := json.Unmarshal(v, &s)
			if err != nil {
				return err
			}

			scripts = append(scripts, s)
		}

		return nil
	})
	return scripts, err
}

// GetScript takes an name and returns their whole script object.
func (sr *scriptRepository) GetScript(name string) (*model.Script, error) {
	var s *model.Script
	err := sr.DB.View(func(tx *bolt.Tx) error {
		b := tx.Bucket(scriptBucket)
		v := b.Get([]byte(name))
		if v == nil {
			return nil
		}
		s = &model.Script{}
		err := json.Unmarshal(v, &s)
		return err
	})
	return s, err
}

// SaveScript persists a script in BoltStore.
func (sr *scriptRepository) SaveScript(u *model.Script) error {
	err := sr.DB.Update(func(tx *bolt.Tx) error {
		b := tx.Bucket(scriptBucket)
		buf, err := json.Marshal(u)
		b.Put([]byte(u.Name), buf)
		return err
	})
	return err
}

// DeleteScript removes any saved script object matching the name
func (sr *scriptRepository) DeleteScript(name string) error {
	err := sr.DB.Update(func(tx *bolt.Tx) error {
		b := tx.Bucket(scriptBucket)
		b.Delete([]byte(name))
		return nil
	})
	return err
}

// DeleteAllScripts deletes the Bolt bucket holding scripts and recreates
// it, essentially deleting all objects.
func (sr *scriptRepository) DeleteAllScripts() error {
	err := sr.DB.Update(func(tx *bolt.Tx) error {
		err := tx.DeleteBucket(scriptBucket)
		if err != nil {
			return err
		}
		_, err = tx.CreateBucket(scriptBucket)
		if err != nil {
			return err
		}

		return nil
	})
	return err
}
