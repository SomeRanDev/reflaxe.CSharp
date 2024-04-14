package cscompiler.helpers;

#if (macro || cs_runtime)

class Printer {

	var _level: Int;
	var _buf: StringBuf;
	var _beginLine: Bool;
	final _indent: String;
	final _newline: String;

	public function new(indent: String = '  ', newline: String = '\n') {
		_indent = indent;
		_newline = newline;
		_beginLine = false;
		clear();
	}

	public inline function indent() {
		_level++;
	}

	public inline function unindent() {
		_level--;
	}

	public function write(s: String) {
		if (_beginLine) {
			tab();
			_beginLine = false;
		}
		_buf.add(s);
		return this;
	}

	public extern inline overload function writeln() {
		return newline();
	}

	public extern inline overload function writeln(s: String) {
		write(s);
		return newline();
	}

	function _writeln(s: String = "") {
		write(s);
		return newline();
	}

	public function newline() {
		_buf.add(_newline);
		_beginLine = true;
		return this;
	}

	public function tab() {
		for (_ in 0..._level)
			_buf.add(_indent);
		return this;
	}

	public extern inline overload function line() {
		return newline();
	}

	public extern inline overload function line(s: String) {
		return _line(s);
	}

	function _line(s: String) {
		tab();
		_buf.add(s);
		return newline();
	}

	public inline function clear() {
		_level = 0;
		_buf = new StringBuf();
	}

	public function toString() {
		return _buf.toString();
	}

}

#end
