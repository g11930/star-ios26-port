#!/usr/bin/env python3
"""Bracket-balance check for a JavaScript file, ignoring strings and comments.

Counting raw braces gives a false mismatch because literals such as "{" appear in the code,
so this walks the source with a small state machine and reports the first real problem.
"""
import sys

PAIRS = {")": "(", "]": "[", "}": "{"}


def check(path):
    src = open(path, encoding="utf-8").read()
    stack = []
    errors = []
    i = 0
    n = len(src)
    line = 1
    while i < n:
        c = src[i]
        if c == "\n":
            line += 1
            i += 1
            continue
        if c in "\"'`":
            quote = c
            start = line
            i += 1
            closed = False
            while i < n:
                if src[i] == "\\":
                    i += 2
                    continue
                if src[i] == quote:
                    i += 1
                    closed = True
                    break
                if src[i] == "\n":
                    line += 1
                i += 1
            if not closed:
                errors.append("unterminated string starting at line %d" % start)
                break
            continue
        if c == "/" and i + 1 < n and src[i + 1] == "/":
            while i < n and src[i] != "\n":
                i += 1
            continue
        if c == "/" and i + 1 < n and src[i + 1] == "*":
            i += 2
            while i + 1 < n and not (src[i] == "*" and src[i + 1] == "/"):
                if src[i] == "\n":
                    line += 1
                i += 1
            i += 2
            continue
        if c in "([{":
            stack.append((c, line))
        elif c in ")]}":
            if not stack:
                errors.append("extra %s at line %d" % (c, line))
            else:
                opened, oline = stack.pop()
                if opened != PAIRS[c]:
                    errors.append("mismatch %s at line %d, opened %s at line %d"
                                  % (c, line, opened, oline))
        i += 1
    for opened, oline in stack:
        errors.append("unclosed %s opened at line %d" % (opened, oline))
    return errors


if __name__ == "__main__":
    problems = check(sys.argv[1])
    if problems:
        print("BRACKET ERRORS:")
        for p in problems:
            print("  " + p)
        sys.exit(1)
    print("brackets balanced, no unterminated strings")
