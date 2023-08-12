defmodule Tucan.Options do
  def tooltip(value) do
    cond do
      is_boolean(value) -> {:ok, value}
      value == :encoding -> {:ok, true}
      value == :data -> {:ok, [content: "data"]}
      true -> "expected :tooltip to be boolean, :encoding or :data, got: #{inspect(value)}"
    end
  end
end
