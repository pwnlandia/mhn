package api

import (
	"errors"
	"fmt"
	"net/http"

	"github.com/gorilla/mux"
	"github.com/pwnlandia/mhn/auth"
	"github.com/pwnlandia/mhn/config"
	"github.com/pwnlandia/mhn/script"
	"github.com/pwnlandia/mhn/user"
)

var (
	// ErrMissingID is returned when you made a call that isn't supported
	// without an ID in the URI
	ErrMissingID = errors.New("Missing identifier in URI") // 400
	// ErrMismatchedID is returned when the post body doesn't match the URI
	ErrMismatchedID = errors.New("URI doesn't match provided data") // 400
	// ErrBodyRequired is returned if a request did not contain a body when one
	// was needed.
	ErrBodyRequired = errors.New("Body is required for this endpoint") // 400
)

// Handler provides an interface for all api/calls.
type Handler interface {
	Status() http.HandlerFunc
	NewMux() *http.ServeMux
}

type apiHandler struct {
	userHandler   UserHandler
	scriptHandler ScriptHandler
	midHandler    MiddlewareHandler
	authHandler   AuthHandler
	configHandler ConfigHandler
	Version       string
}

// NewHandler creates a new apiHandler with given UserService and ConfigService.
func NewHandler(version string, us user.Service, ss script.Service, cs config.Service) Handler {
	// TODO: Make RBAC persistent if needed.
	rbac := auth.InitRBAC()
	uh := NewUserHandler(us)
	sh := NewScriptHandler(ss)
	mh := NewMiddlewareHandler(cs, rbac)
	ah := NewAuthHandler(cs, us)
	ch := NewConfigHandler(cs)
	return &apiHandler{userHandler: uh, scriptHandler: sh, midHandler: mh, authHandler: ah, configHandler: ch, Version: version}
}

// Status returns the current version of the server.
func (h *apiHandler) Status() http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintf(w, "Version: %s", h.Version)
	}
}

// TODO: Break this up into sub routers within the handlers.
func (h *apiHandler) router() *mux.Router {
	r := mux.NewRouter()

	r.HandleFunc("/status", h.Status())

	r.HandleFunc("/api/authenticate", h.authHandler.Authenticate()).Methods("POST")

	r.HandleFunc("/api/config/superadmin/{id}", h.configHandler.SuperAdmin()).Methods("POST")

	// api/user
	r.HandleFunc("/api/user/",
		h.midHandler.Permission(
			auth.PermUserRead,
			h.userHandler.Get(),
		)).Methods("GET")

	r.HandleFunc("/api/user/{id}",
		h.midHandler.Permission(
			auth.PermUserRead,
			h.userHandler.Get(),
		)).Methods("GET")

	// TODO: Add a POST request that takes a name and optional password to create a new user.
	r.HandleFunc("/api/user/",
		h.midHandler.Permission(
			auth.PermUserWrite,
			h.userHandler.Put(),
		)).Methods("PUT") // Funnel bad request for proper response.

	r.HandleFunc("/api/user/{id}",
		h.midHandler.Permission(
			auth.PermUserWrite,
			h.userHandler.Put(),
		)).Methods("PUT")

	r.HandleFunc("/api/user/",
		h.midHandler.Permission(
			auth.PermUserWrite,
			h.userHandler.Delete(),
		)).Methods("DELETE")

	r.HandleFunc("/api/user/{id}",
		h.midHandler.Permission(
			auth.PermUserWrite,
			h.userHandler.Delete(),
		)).Methods("DELETE")

	// api/script
	r.HandleFunc("/api/script/",
		h.midHandler.Permission(
			auth.PermUserRead,
			h.scriptHandler.Get(),
		)).Methods("GET")

	r.HandleFunc("/api/script/{id}",
		h.midHandler.Permission(
			auth.PermUserRead,
			h.scriptHandler.Get(),
		)).Methods("GET")

	r.HandleFunc("/api/script/",
		h.midHandler.Permission(
			auth.PermUserWrite,
			h.scriptHandler.Put(),
		)).Methods("PUT") // Funnel bad request for proper response.

	r.HandleFunc("/api/script/{id}",
		h.midHandler.Permission(
			auth.PermUserWrite,
			h.scriptHandler.Put(),
		)).Methods("PUT")

	r.HandleFunc("/api/script/",
		h.midHandler.Permission(
			auth.PermUserWrite,
			h.scriptHandler.Delete(),
		)).Methods("DELETE")

	r.HandleFunc("/api/script/{id}",
		h.midHandler.Permission(
			auth.PermUserWrite,
			h.scriptHandler.Delete(),
		)).Methods("DELETE")

	return r
}

// NewMux returns a new http.ServeMux with established routes.
func (h *apiHandler) NewMux() *http.ServeMux {
	r := h.router()

	s := http.NewServeMux()
	s.Handle("/", r)
	return s
}
