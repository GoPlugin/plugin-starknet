// Code generated by mockery v2.14.0. DO NOT EDIT.

package mocks

import (
	mock "github.com/stretchr/testify/mock"

	keys "github.com/goplugin/plugin-starknet/relayer/pkg/plugin/keys"
)

// Keystore is an autogenerated mock type for the Keystore type
type Keystore struct {
	mock.Mock
}

// Get provides a mock function with given fields: id
func (_m *Keystore) Get(id string) (keys.Key, error) {
	ret := _m.Called(id)

	var r0 keys.Key
	if rf, ok := ret.Get(0).(func(string) keys.Key); ok {
		r0 = rf(id)
	} else {
		r0 = ret.Get(0).(keys.Key)
	}

	var r1 error
	if rf, ok := ret.Get(1).(func(string) error); ok {
		r1 = rf(id)
	} else {
		r1 = ret.Error(1)
	}

	return r0, r1
}

type mockConstructorTestingTNewKeystore interface {
	mock.TestingT
	Cleanup(func())
}

// NewKeystore creates a new instance of Keystore. It also registers a testing interface on the mock and a cleanup function to assert the mocks expectations.
func NewKeystore(t mockConstructorTestingTNewKeystore) *Keystore {
	mock := &Keystore{}
	mock.Mock.Test(t)

	t.Cleanup(func() { mock.AssertExpectations(t) })

	return mock
}
