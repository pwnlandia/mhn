package model

// Script is a stored shell/batch script
type Script struct {
	Name        string
	Description string
	Body        string // The full text body of the script.
}

// NewScript
func NewScript(name, description, body string) *Script {
	return &Script{Name: name, Description: description, Body: body}
}
