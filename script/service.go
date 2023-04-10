package script

import (
	"errors"

	"github.com/pwnlandia/mhn/model"
)

var (
	// ErrScriptNotFound means the script name was not found in the repo
	ErrScriptNotFound = errors.New("script not found")

	// ErrScriptAlreadyExists is returned if a create is called on an existing script
	ErrScriptAlreadyExists = errors.New("script with that name exists")
)

// Service provides an interface for all business operations on the Script model.
type Service interface {
	GetAllScripts() ([]*model.Script, error)
	GetScript(name string) (*model.Script, error)
	SaveScript(s *model.Script) error
	DeleteScript(name string) error
	DeleteAllScripts() error
}
