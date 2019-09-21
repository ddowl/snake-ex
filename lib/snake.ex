defmodule SnakeEx do
  @behaviour Ratatouille.App
  @block "█"

  import Ratatouille.View

  def init(%{window: window}) do
    log_filename = __ENV__.file |> Path.join("../snake.log") |> Path.expand()
    log_file = File.open!(log_filename, [:write, :utf8])
    IO.puts(log_file, "in init!")

    grid_height = window.height - 4
    grid_width = window.width - 4

    %{
      pellet: rand_pos(grid_width, grid_height),
      snake: [rand_pos(grid_width, grid_height)],
      height: grid_height,
      width: grid_width,
      log_file: log_file
    }
  end

  def update(model, msg) do
    case msg do
      {:event, %{key: key}} ->
        IO.puts(model.log_file, "key pressed: #{key}")
        model

      _ ->
        model
    end
  end

  def render(model) do
    view do
      panel(
        color: :green,
        title: "Snake! Grab the pellet, and avoid the walls! (Press q to quit)"
      ) do
        canvas(height: model.height, width: model.width) do
          pellet_cell(model)
          snake_cells(model)
        end
      end
    end
  end

  def run() do
    Ratatouille.run(__MODULE__)
  end

  defp rand_pos(width, height) do
    {:rand.uniform(width - 1), :rand.uniform(height - 1)}
  end

  defp pellet_cell(%{pellet: {x, y}}) do
    canvas_cell(x: x, y: y, char: @block, color: :red)
  end

  defp snake_cells(%{snake: cells}) do
    Enum.map(cells, fn {x, y} -> canvas_cell(x: x, y: y, char: @block, color: :green) end)
  end
end
