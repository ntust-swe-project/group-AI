---
name: gut
description: Godot Unit Testing (GUT) framework for GDScript. Covers test structure, assertions, doubles/mocks, async testing, memory management, and CLI execution. Use when writing tests, understanding test patterns, or troubleshooting test failures.
---

# GUT Testing Framework Skill

> **group-AI copy.** Source: `rockerBOO/gut-skill` commit `0259877` (GPL-3.0, see `LICENSE` in this folder). Pinned to **GUT 9.7.1 on Godot 4.7**.
>
> Changes from the original (2026-11-10):
> 1. Doubles no longer return `null`. Since GUT 9.7.0 (Godot 4.7 type checks) they return the default value of the method's declared return type, and `to_do_nothing()` does the same. Fixed in "Creating Doubles" and "Stubbing".
> 2. Added: stubbing a return value of the wrong type logs a GUT error and an engine error.
> 3. Dropped `-d` from every command. With `-d`, a test script that fails to parse drops Godot into its interactive debugger and the run hangs until killed. Without `-d`, GUT skips that script and still exits `0`; this repo's `test/hooks/post_run.gd` turns that into exit `1`.
>
> Checked against GUT 9.7.1 source: every function name, CLI flag and `.gutconfig.json` key below exists. Behaviour claims were only checked against the 9.6.0 and 9.7.0 release notes.

GUT is a unit testing framework for Godot (GDScript). Test files live in `res://test/` and must be named with `test_` prefix.

## Test File Structure

```gdscript
extends GutTest

# Lifecycle hooks (all optional)
func before_all():  pass   # once before all tests
func before_each(): pass   # before each test
func after_each():  pass   # after each test
func after_all():   pass   # once after all tests

# Tests: any method starting with "test_"
func test_something():
    assert_eq(1, 1, "optional message")
```

## Key Rules
- Files must `extends GutTest`
- Test methods must start with `test_`
- Each test needs at least one assert, `pending()`, `pass_test()`, or `fail_test()` — else marked risky
- Group tests with inner classes starting with `Test` that also `extend GutTest`
- Doubles must NOT be created in `before_all` or referenced in `after_all` — they are freed after each test finishes

## Assertions Reference

### Equality / Comparison
```gdscript
assert_eq(got, expected, msg="")       # ==
assert_ne(got, expected, msg="")       # !=
assert_gt(got, expected, msg="")       # >
assert_gte(got, expected, msg="")      # >=
assert_lt(got, expected, msg="")       # <
assert_lte(got, expected, msg="")      # <=
assert_between(got, low, high, msg="") # low <= got <= high
assert_almost_eq(got, expected, error_interval, msg="")
assert_almost_ne(got, expected, error_interval, msg="")
assert_eq_deep(v1, v2)                 # deep comparison
assert_ne_deep(v1, v2)
```

### Truthiness / Null / Type
```gdscript
assert_true(got, msg="")
assert_false(got, msg="")
assert_null(got, msg="")
assert_not_null(got, msg="")
assert_is(object, a_class, msg="")
assert_typeof(object, type, msg="")
assert_not_typeof(object, type, msg="")
assert_same(v1, v2, msg="")            # same instance
assert_not_same(v1, v2, msg="")
```

### Collections / Strings
```gdscript
assert_has(obj, element, msg="")
assert_does_not_have(obj, element, msg="")
assert_string_contains(text, search, match_case=true)
assert_string_starts_with(text, search, match_case=true)
assert_string_ends_with(text, search, match_case=true)
```

### Object / Properties
```gdscript
assert_has_method(obj, method, msg="")
assert_has_signal(object, signal_name, msg="")
assert_exports(obj, property_name, type)
assert_property(obj, property_name, default_value, new_value)
assert_accessors(obj, property, default, set_to)
```

### Signals
```gdscript
# Must watch_signals first (or use wait_for_signal which does it automatically)
watch_signals(obj)
assert_signal_emitted(obj, signal_name, msg="")
assert_signal_not_emitted(obj, signal_name, msg="")
assert_signal_emit_count(obj, signal_name, count, msg="")
assert_signal_emitted_with_parameters(obj, signal_name, params, call_index=-1)
```

### Errors / Warnings
```gdscript
assert_engine_error(text, msg="")
assert_engine_error_count(count, msg="")
assert_push_error(text, msg="")
assert_push_error_count(count, msg="")
assert_push_warning(text, msg="")
assert_push_warning_count(count, msg="")
```

### Memory
```gdscript
assert_no_new_orphans(msg="")
assert_freed(obj, title="something")
assert_not_freed(obj, title="something")
```

### Test Flow
```gdscript
pending(text)       # mark test as pending/todo (text required)
pass_test(text)     # force pass (text required)
fail_test(text)     # force fail (text required)
```

## Memory Management

Always clean up nodes to avoid orphan warnings:

```gdscript
# autofree calls free() after each test — but NOT in the scene tree
var node = autofree(Node.new())
var node = autoqfree(Node.new())  # uses queue_free()

# add to tree AND auto-free — use these when you need the node in the tree
var node = add_child_autofree(Node2D.new())
var node = add_child_autoqfree(Node2D.new())
```

- Doubles/partial_doubles are freed automatically — no manual cleanup needed
- Do NOT use autofree methods in `before_all` (freed after first test)
- `autofree`/`autoqfree` objects are NOT in the scene tree — they still cause `assert_no_new_orphans` to fail. Use `add_child_autofree` instead if you also need `assert_no_new_orphans` to pass.

## Doubles, Stubs, Spies

### Creating Doubles
```gdscript
var MyScript = load('res://my_script.gd')
var MyScene  = load('res://my_scene.tscn')

# Script double — methods do nothing and return the default value of their
# declared return type (0 for int, "" for String, null only for Variant/Object)
var dbl = double(MyScript).new()

# Scene double
var dbl_scene = double(MyScene).instantiate()

# Partial double — retains original behavior unless stubbed
var pdbl = partial_double(MyScript).new()

# Built-in types
var dbl_node = double(Node2D).new()

# Autoload singletons
var dbl_singleton = double_singleton(MySingleton)
var pdbl_singleton = partial_double_singleton(MySingleton)
```

Inner classes need registration first (do in `before_all` or pre-run hook):
```gdscript
func before_all():
    register_inner_classes(SomeScript)

func test_foo():
    var dbl = double(SomeScript.InnerClass).new()
```

Classes with static methods crash when doubled. Use `ignore_method_when_doubling` first:
```gdscript
func before_each():
    ignore_method_when_doubling(MyScript, 'my_static_method')

func test_foo():
    var dbl = double(MyScript).new()  # now safe
```

### Stubbing
```gdscript
# Instance-level stub
stub(dbl.some_method).to_return(42)
stub(dbl.some_method).to_do_nothing()     # returns the return type's default value
stub(dbl.some_method).to_call_super()
stub(dbl.some_method).to_call(func(val): return val * 2)

# With specific parameters (two equivalent forms)
stub(dbl.some_method.bind("a")).to_return(999)
stub(dbl, "some_method").when_passed("a").to_return(999)

# Script-level stub (applies to all instances without their own stub)
# Best set in before_each
stub(MyScript, "some_method").to_return(111)

# Fix null default params when calling super
stub(dbl, 'increment').param_defaults([1])

# Add parameters for vararg built-in methods (must be before double())
stub(Node, 'rpc_id').to_do_nothing().param_count(5)
```

The stubbed value must match the method's declared return type. A wrong type
(e.g. a String from a method declared `-> int`) logs `[GUT ERROR] ... stubbed to
return invalid value` plus an engine `SCRIPT ERROR`, and the test keeps running.

### Spying
```gdscript
assert_called(dbl, 'method_name')
assert_called(dbl, 'method_name', [arg1, arg2])  # with params
assert_not_called(dbl, 'method_name')
assert_called_count(dbl.foo, 3)                  # callable form

var params = get_call_parameters(dbl, 'method_name')       # last call
var params = get_call_parameters(dbl, 'method_name', 4)    # 4th call
var count  = get_call_count(dbl, 'method_name')
```

Only user-defined methods are spied; native Godot methods are not included unless using `INCLUDE_NATIVE` strategy.

## Async / Awaiting

Always use GUT's wait methods — not raw `await signal` — to prevent test hangs:

```gdscript
await wait_seconds(2.5)
await wait_seconds(0.1, "waiting for timer")

await wait_physics_frames(2)   # wait at least 2 for reliability
await wait_idle_frames(10)     # alias: wait_process_frames

# Wait for signal OR timeout (returns true if signal fired)
await wait_for_signal(my_obj.some_signal, 5)
assert_true(await wait_for_signal(my_obj.done, 3), "should fire")

# Wait until callable returns true
await wait_until(func(): return is_ready, 5)

# Wait while callable returns true
await wait_while(func(): return is_busy, 10)
```

`wait_for_signal` also calls `watch_signals` internally.

## Simulate

Manually drive `_process` / `_physics_process` without running the game loop:

```gdscript
# simulate(obj, times, delta, check_is_processing=false)
var obj = add_child_autofree(MyObject.new())
gut.simulate(obj, 20, 0.1)
assert_eq(obj.a_number, 20)
```

Add nodes to the tree (`add_child_autofree`) if using `check_is_processing=true`. Timers do not fire during simulate — use `await` for those.

## Parameterized Tests

```gdscript
var params = [[1, 2, 3], [4, 5, 9]]
func test_add(p=use_parameters(params)):
    assert_eq(p[0] + p[1], p[2])

# Named parameters (more readable)
var named = ParameterFactory.named_parameters(
    ['a', 'b', 'result'],
    [[1, 2, 3], [10, 5, 15]]
)
func test_add_named(p=use_parameters(named)):
    assert_eq(p.a + p.b, p.result)
```

## Inner Test Classes

```gdscript
extends GutTest

class TestFeatureA:
    extends GutTest

    var _subject = null

    func before_each():
        _subject = Subject.new()

    func test_something():
        assert_true(_subject.works())

class TestFeatureB:
    extends GutTest
    # ...
```

Class name must start with `Test`. Cannot nest inner test classes.

## Hooks (Pre/Post Run)

```gdscript
# res://test/hooks/pre_run.gd
extends GutHookScript

func run():
    AudioServer.set_bus_volume_db(0, -INF)  # mute audio
    register_inner_classes(load('res://some_script.gd'))
    # abort() to cancel the test run
```

Configure in `.gutconfig.json`:
```json
{
  "pre_run_script": "res://test/hooks/pre_run.gd",
  "post_run_script": "res://test/hooks/post_run.gd"
}
```

## Running Tests (CLI Only)

Tests are run from the command line — no GUI required. Always include `-gexit` so the process exits after the run. Returns `0` on success, `1` on any failure (suitable for CI).

**Do not add `-d` in non-interactive runs** (agents, CI): a parse error then opens Godot's interactive debugger and the process hangs. **A script that fails to parse is skipped with only a warning and does not fail the run** — in this repo `test/hooks/post_run.gd` (set as `post_run_script` in `.gutconfig.json`) fails the run when any `test_*.gd` was not collected or no test ran.

```bash
# Run all tests in a directory
godot -s addons/gut/gut_cmdln.gd --path "$PWD" -gdir=res://test -gexit

# Run with subdirectory discovery
godot -s addons/gut/gut_cmdln.gd --path "$PWD" -gdir=res://test -ginclude_subdirs -gexit

# Run a specific test file
godot -s addons/gut/gut_cmdln.gd --path "$PWD" -gtest=res://test/unit/test_foo.gd -gexit

# Run tests matching a name substring
godot -s addons/gut/gut_cmdln.gd --path "$PWD" -gdir=res://test -gunit_test_name=test_my_method -gexit

# Run only scripts whose filename contains a string
godot -s addons/gut/gut_cmdln.gd --path "$PWD" -gdir=res://test -gselect=foo -gexit

# Headless / CI (Godot 4)
godot --headless -s addons/gut/gut_cmdln.gd --path "$PWD" -gdir=res://test -gexit
```

### Config File (`.gutconfig.json`)

Put this at the project root to avoid repeating CLI flags:

```json
{
  "dirs": ["res://test/unit/", "res://test/integration/"],
  "include_subdirs": true,
  "prefix": "test_",
  "suffix": ".gd",
  "should_exit": true,
  "log_level": 1,
  "ignore_pause": true
}
```

With a config file in place, the minimum invocation is:
```bash
godot --headless -s addons/gut/gut_cmdln.gd --path "$PWD"
```

Key CLI flags:
| Flag | Purpose |
|---|---|
| `-gdir=<path>` | Directory to search for tests (repeatable) |
| `-gtest=<path>` | Run a specific test file |
| `-ginclude_subdirs` | Recurse into subdirectories |
| `-gunit_test_name=<str>` | Only run tests whose name contains this string |
| `-gselect=<str>` | Only run scripts whose filename contains this string |
| `-ginner_class=<str>` | Only run inner classes whose name contains this string |
| `-gexit` | Exit when done (required for CI) |
| `-gexit_on_success` | Only exit if all tests pass |
| `-glog=<0-3>` | Log verbosity (default 1) |
| `-gignore_pause` | Skip any `pause_before_teardown()` calls |
| `-gpre_run_script=<path>` | Pre-run hook script |
| `-gpost_run_script=<path>` | Post-run hook script |

## GDScript Toolkit

### gdlint — Static Analysis

```bash
gdlint res/scripts/my_script.gd
gdlint src/                         # lint a directory
```

Outputs errors like:
```
my_script.gd:96: Error: Function argument name "aOrigin" is not valid (function-argument-name)
```

### gdformat — Auto-formatter

**Always use with version control** — formats in-place and can't be undone.

```bash
gdformat my_script.gd               # format single file
gdformat src/                       # format directory
gdformat --check src/               # dry-run: exit 1 if any file would change (use in CI)
```

### gdparse — Parser / AST

```bash
gdparse my_script.gd -p             # print parse tree
```

### gdradon — Cyclomatic Complexity

```bash
gdradon cc src/my_script.gd         # complexity per function/class
```

Output (A=low, F=high complexity):
```
src/my_script.gd
    F 1:0 foo - B (8)
    C 10:0 MyClass - A (2)
```

### CI / GitHub Actions

```yaml
- uses: Scony/godot-gdscript-toolkit@master
- run: gdformat --check source/
- run: gdlint source/
```

## Common Patterns

### Test a Node that needs the scene tree
```gdscript
var _subject: MyNode

func before_each():
    _subject = add_child_autofree(MyNode.new())

func test_something():
    assert_eq(_subject.value, 0)
```

### Test a signal
```gdscript
func test_emits_signal():
    var obj = autofree(MyClass.new())
    watch_signals(obj)
    obj.do_thing()
    assert_signal_emitted(obj, 'thing_done')
```

### Test with a double dependency
```gdscript
var MyService = load('res://services/my_service.gd')

func test_calls_service():
    var svc = double(MyService).new()
    stub(svc.fetch).to_return({"id": 1})

    var subject = autofree(MyClass.new())
    subject.service = svc
    subject.run()

    assert_called(svc, 'fetch')
```
