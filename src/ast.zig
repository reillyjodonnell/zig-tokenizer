const std = @import("std");

const Location = struct {
    line: usize,
    column: usize,
};

const Loc = struct {
    start: Location,
    end: Location,
};

const SourceType = enum { script, module };

const Type = enum { program };

const Program = struct { type: Type.Program, body: null, comments: null, sourceType: SourceType.script, loc: Loc, parent: null, tokens: null };

pub fn ast() void {}

test "ast" {}
