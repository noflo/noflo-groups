# @noflo/groups

Bracket Utilities for [NoFlo](http://noflojs.org/)

This package provides utility components to work with NoFlo groups
(brackets), the stream metadata that travels with information packets.

## Usage

Install the package:

    npm install @noflo/groups

The components are then available under the `groups/` namespace, for
example `groups/Group` or `groups/CollectTree`.

Components include:

- `Group`, `GenerateGroup`, `GroupZip`, `GroupByObjectKey` — add group
  structure to streams
- `ReadGroup`, `ReadGroups`, `MapGroup`, `Regroup`, `RemoveGroups`,
  `FirstGroup`, `LastGroup`, `MergeGroups`, `FilterByGroup` — read,
  rewrite, or filter group structure
- `CollectGroups`, `CollectTree`, `CollectObject` — collapse bracketed
  streams into data structures
- `SendByGroup` — store packets and release them by group
- `Objectify` — turn matching groups into object keys

The `graphs/ObjectifyByGroup` graph composes several of these components
into a group-to-object converter.
