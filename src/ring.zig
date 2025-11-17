const std = @import("std");

// each node has multiple shards
// all the nodes are places on ring

// To keep things simple, lets only do <string>:<string>

pub const HashFn = *const fn ([]const u8) u8;

pub fn hashFn(input: []const u8) u8 {
    var hash: u8 = 0;
    for (input) |byte| {
        hash +%= byte; // wrapping add
    }
    return hash;
}

fn Ring(comptime V: type) type {
    const shards = 256;

    return struct {
        allocator: std.mem.Allocator,
        shard_maps: []std.StringHashMap(V),
        hash_fn: HashFn,
        const Self = @This();

        pub fn init(allocator: std.mem.Allocator, hash_fn: HashFn) !Self {
            // create a map for each shard
            // allocate this on the allocator
            const shard_maps = try allocator.alloc(std.StringHashMap(V), shards);

            var i: usize = 0;
            while (i < shards) : (i += 1) {
                shard_maps[i] = std.StringHashMap(V).init(allocator);
            }

            return .{ .shard_maps = shard_maps, .allocator = allocator, .hash_fn = hash_fn };
        }

        pub fn deinit(self: *Self) void {
            // deinit each shard map and free the array
            for (self.shard_maps) |*shard_map| {
                shard_map.deinit();
            }

            self.allocator.free(self.shard_maps);
        }

        pub fn put(self: *Self, key: []const u8, value: V) !void {
            const bucket = self.hash_fn(key);
            try self.shard_maps[bucket].put(key, value);
        }

        pub fn get(self: *Self, key: []const u8) ?V {
            const bucket = self.hash_fn(key);
            return self.shard_maps[bucket].get(key);
        }
    };
}

// Tests
test "ring put and get" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var r = try Ring(i32).init(allocator, &hashFn);
    defer r.deinit();

    try r.put("key1", 100);
    try std.testing.expectEqual(@as(?i32, 100), r.get("key1"));
}

test "ring get nonexistent key" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var r = try Ring(i32).init(allocator, &hashFn);
    defer r.deinit();

    try std.testing.expectEqual(@as(?i32, null), r.get("nonexistent"));
}

test "ring overwrite value" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var r = try Ring(i32).init(allocator, &hashFn);
    defer r.deinit();

    try r.put("key", 100);
    try r.put("key", 200);
    try std.testing.expectEqual(@as(?i32, 200), r.get("key"));
}

test "ring multiple keys" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var r = try Ring(i32).init(allocator, hashFn);
    defer r.deinit();

    try r.put("a", 1);
    try r.put("b", 2);
    try r.put("c", 3);

    try std.testing.expectEqual(@as(?i32, 1), r.get("a"));
    try std.testing.expectEqual(@as(?i32, 2), r.get("b"));
    try std.testing.expectEqual(@as(?i32, 3), r.get("c"));
}

test "hash function consistency" {
    const h1 = hashFn("test");
    const h2 = hashFn("test");
    try std.testing.expectEqual(h1, h2);
}
