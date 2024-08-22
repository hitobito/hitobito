# Roles

Roles are used to model the membership of a person in a group. 
* The role type is used to determine  the permissions that a person has within the group.
* A Role can be valid for an unlimited period of time, or it can have a start and/or end date.

A role that is currently valid is called an "active" role.  
A role whose end date is in the past is called an "ended" role.  
A role whose start date is in the future is called a "future" role.

The default scope on `Role` returns only currently active roles. Use the scope `with_inactive`
to include ended and future roles as well.

## Overview
* [Class attributes](class_attributes.md)
* [Basic Permission Roles](basic_permission_roles.md)
