-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

TestGrammarApply = {}

function TestGrammarApply:test_apply_on_record()
	-- Given
	local buf = haka.vbuffer_from("abcdefghijklmnopqrstuvwxyz0123456789")
	local grammar = haka.grammar.new("test", function ()
		elem = record{
			field("token", token("[a-z]*")),
			field("num", token("[0-9]*"))
		}:apply(function (value)
			value.ok = true
		end)

		export(elem)
	end)

	-- When
	local result = grammar.elem:parse(buf:pos('begin'))

	assertEquals(result.ok, true)
end

function TestGrammarApply:test_apply_on_named_record()
	-- Given
	local buf = haka.vbuffer_from("abcdefghijklmnopqrstuvwxyz0123456789")
	local grammar = haka.grammar.new("test", function ()
		elem = record{
			field("rec", record{
					field("token", token("[a-z]*")),
					field("num", token("[0-9]*"))
				}:apply(function (value)
					value.ok = true
				end)
			)
		}

		export(elem)
	end)

	-- When
	local result = grammar.elem:parse(buf:pos('begin'))

	assertEquals(result.rec.ok, true)
end

function TestGrammarApply:test_apply_on_token()
	-- Given
	local buf = haka.vbuffer_from("abcdefghijklmnopqrstuvwxyz0123456789")
	local grammar = haka.grammar.new("test", function ()
		elem = record{
			field("token", token("[a-z]*"))
				:apply(function (value, res)
					res.ok = true
				end)
		}

		export(elem)
	end)

	-- When
	local result = grammar.elem:parse(buf:pos('begin'))

	assertEquals(result.ok, true)
end

function TestGrammarApply:test_apply_on_proxy()
	-- Given
	local buf = haka.vbuffer_from("abcdefghijklmnopqrstuvwxyz0123456789")
	local grammar = haka.grammar.new("test", function ()
		rec = record{
			field("token", token("[a-z]*")),
			field("num", token("[0-9]*"))
		}

		elem = rec:apply(function (value)
			value.ok = true
		end)

		export(elem)
	end)

	-- When
	local result = grammar.elem:parse(buf:pos('begin'))

	assertEquals(result.ok, true)
end

function TestGrammarApply:test_const()
	-- Given
	local buf = haka.vbuffer_from("abcdefghijklmnopqrstuvwxyz123456789")
	local grammar = haka.grammar.new("test", function ()
		elem = record{
			field("token", token("[a-z]*"))
				:const("abcdefghijklmnopqrstuvwxyz"),
			field("num", token("[0-9]*"))
		}

		export(elem)
	end)

	-- When
	local result, err = grammar.elem:parse(buf:pos('begin'))

	-- Should not fail
	assertEquals(err, nil)
end

function TestGrammarApply:test_const_convert()
	-- Given
	local buf = haka.vbuffer_from("abcdefghijklmnopqrstuvwxyz123456789")
	local grammar = haka.grammar.new("test", function ()
		elem = record{
			field("token", token("[a-z]*")),
			field("num", token("[0-9]*"))
				:convert(haka.grammar.converter.tonumber("%d"))
				:const(function () return 123456789 end)
		}

		export(elem)
	end)

	-- When
	local result, err = grammar.elem:parse(buf:pos('begin'))

	-- Should not fail
	assertEquals(err, nil)
end

function TestGrammarApply:test_const_failure()
	-- Given
	local buf = haka.vbuffer_from("abcdefghijklmnopqrstuvwxyz0123456789")
	local grammar = haka.grammar.new("test", function ()
		rec = record{
			field("token", token("[a-z]*"))
				:const("abcdefghijrstuvwxyz"),
			field("num", token("[0-9]*"))
		}

		elem = rec:apply(function (value)
			value.ok = true
		end)

		export(elem)
	end)

	-- When
	local result, err = grammar.elem:parse(buf:pos('begin'))

	-- Should fail
	assertNotEquals(err, nil)
end

addTestSuite('TestGrammarApply')
