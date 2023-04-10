package service

import (
	"errors"

	"github.com/pwnlandia/mhn/model"
	"github.com/pwnlandia/mhn/script"
)

type scriptService struct {
	repo script.Repository
}

var ErrScriptNil = errors.New("script cannot be nil")
var ErrScriptMustHaveName = errors.New("scripts must have a name")

// NewScriptService returns a new instance of a scriptService initialized with the
// given repository.
func NewScriptService(repo script.Repository) script.Service {
	return scriptService{repo}
}

// GetAllScripts returns a slice of pointers to all scripts stored in the repo.
func (ss scriptService) GetAllScripts() ([]*model.Script, error) {
	return ss.repo.GetAllScripts()
}

// GetScript returns a pointer to the script with a matching name. If none is found,
// an error is returned and the script is nil.
func (ss scriptService) GetScript(name string) (*model.Script, error) {
	return ss.repo.GetScript(name)
}

// SaveScript simply saves a script to the repo.
func (ss scriptService) SaveScript(s *model.Script) error {
	if s == nil {
		return ErrScriptNil
	}
	if s.Name == "" {
		return ErrScriptMustHaveName
	}
	return ss.repo.SaveScript(s)
}

// DeleteScript deletes the specified script in the repository.
func (ss scriptService) DeleteScript(name string) error {
	return ss.repo.DeleteScript(name)
}

// DeleteAllScripts deletes all scripts in the repository.
func (ss scriptService) DeleteAllScripts() error {
	return ss.repo.DeleteAllScripts()
}
