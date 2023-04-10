package model

import "testing"

func TestNewScript(t *testing.T) {
	t.Run("NewScript", func(t *testing.T) {
		s := NewScript("name1", "description1", "body1")

		if s == nil {
			t.Fatal("Script should not be nil")
		}
		assertString(t, s.Name, "name1")
		assertString(t, s.Description, "description1")
		assertString(t, s.Body, "body1")
	})
}

func assertString(t *testing.T, s1 string, s2 string) {
	if s1 != s2 {
		t.Errorf("strings don't match: %s vs %s", s1, s2)
	}
}
