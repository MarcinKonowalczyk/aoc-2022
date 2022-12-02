import std/sequtils

template sum[T](s: seq[T]): T = s.foldl(a + b)
