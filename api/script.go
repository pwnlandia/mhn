package api

import (
	"github.com/pwnlandia/mhn/model"
	"github.com/pwnlandia/mhn/script"

	"encoding/json"
	"errors"
	"log"
	"net/http"

	"github.com/gorilla/mux"
)

var ErrInvalidScriptName = errors.New("Script names must not be blank")

type ScriptHandler interface {
	Get() http.HandlerFunc
	Put() http.HandlerFunc
	Delete() http.HandlerFunc
}

type scriptHandler struct {
	ss script.Service
}

func NewScriptHandler(ss script.Service) ScriptHandler {
	return &scriptHandler{ss}
}

// Delete should handle requests of DELETE /api/script/{id} where id is the script name, or all scripts if id is not specified.
func (h *scriptHandler) Delete() http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		vars := mux.Vars(r)
		id := vars["id"]

		// DELETE /api/script/
		// Delete all scripts
		if id == "" {
			err := h.ss.DeleteAllScripts()
			if err != nil {
				log.Printf("apiScriptDELETEHandler, DeleteAllScripts(), %s", err.Error())
				http.Error(w, err.Error(), http.StatusInternalServerError)
				return
			}
			w.WriteHeader(http.StatusNoContent)
			return
		}

		// Delete script
		s, err := h.ss.GetScript(id)
		if err != nil {
			log.Printf("apiScriptDELETEHandler, GetScript(), %s", err.Error())
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		// If it doesn't already exist, return 404.
		if s == nil {
			http.Error(w, http.StatusText(http.StatusNotFound), http.StatusNotFound)
			return
		}

		err = h.ss.DeleteScript(id)
		if err != nil {
			log.Printf("apiScriptDELETEHandler, DeleteScript(), %s", err.Error())
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		w.WriteHeader(http.StatusNoContent)
		return
	}

}

// Get handles requests to /api/script/{id} where id is the script name, or returns all scripts if id blank.
func (h *scriptHandler) Get() http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		vars := mux.Vars(r)
		id := vars["id"]

		// TODO: Factor out this section into new handler perhaps.
		// "/api/script/"
		if id == "" {
			scripts, err := h.ss.GetAllScripts()
			if err != nil {
				log.Printf("apiScriptGETHandler, GetAllScripts(), %s", err.Error())
				http.Error(w, err.Error(), http.StatusInternalServerError)
				return
			}

			w.WriteHeader(http.StatusOK)
			w.Header().Set("Content-Type", "application/json")
			json.NewEncoder(w).Encode(scripts)
			return
		}

		// Return script if found
		s, err := h.ss.GetScript(id)
		if err != nil {
			log.Printf("apiScriptGETHandler, GetScript(), %s", err.Error())
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		if s == nil {
			http.Error(w, http.StatusText(http.StatusNotFound), http.StatusNotFound)
			return
		}

		w.WriteHeader(http.StatusOK)
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(s)
	}
}

func (h *scriptHandler) Put() http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		var create bool

		vars := mux.Vars(r)
		id := vars["id"]

		// Can't PUT on /script/ without an identifier.
		if id == "" {
			http.Error(w, ErrMissingID.Error(), http.StatusBadRequest)
			return
		}

		// Check to see if this script name already exists
		s, err := h.ss.GetScript(id)
		if err != nil {
			log.Printf("apiScriptPUTHandler, GetScript(), %s", err.Error())
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		// Is this a new Script being created?
		// We want to remember so we know to return 200 vs 201
		if s == nil {
			create = true
		}

		if r.Body == nil {
			http.Error(w, ErrBodyRequired.Error(), http.StatusBadRequest)
			return
		}

		// Decode JSON payload
		sreq := &model.Script{}
		err = json.NewDecoder(r.Body).Decode(sreq)
		if err != nil {
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}

		// Make sure payload name matches ID in URI
		if id != sreq.Name {
			http.Error(w, ErrMismatchedID.Error(), http.StatusBadRequest)
			return
		}

		// Save to database
		err = h.ss.SaveScript(sreq)
		if err != nil {
			log.Printf("apiScriptPUTHandler, SaveScript(), %s", err.Error())
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		// If new script, return 201, if existing, we're updating so return status OK.
		if create {
			w.WriteHeader(http.StatusCreated)
		} else {
			w.WriteHeader(http.StatusOK)
		}

		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(sreq)
	}
}
