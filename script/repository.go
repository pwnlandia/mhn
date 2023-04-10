package script

import (
	"github.com/pwnlandia/mhn/model"
)

// Repository provides an interface for how to store and retrieve Script objects
// from a persistence engine.
type Repository interface {
	GetAllScripts() ([]*model.Script, error)
	GetScript(name string) (*model.Script, error)
	SaveScript(u *model.Script) error
	DeleteScript(name string) error
	DeleteAllScripts() error
}
