defmodule SnakeEx do
  import Ratatouille.View
  import Ratatouille.Constants, only: [key: 1]

  @behaviour Ratatouille.App
  @block "█"

  @up key(:arrow_up)
  @down key(:arrow_down)
  @left key(:arrow_left)
  @right key(:arrow_right)
  @arrows [@up, @down, @left, @right]

  def init(%{window: window}) do
    log_filename = __ENV__.file |> Path.join("../snake.log") |> Path.expand()
    log_file = File.open!(log_filename, [:write, :utf8])
    IO.puts(log_file, "in init!")

    grid_height = window.height - 4
    grid_width = window.width - 4

    %{
      pellet: rand_pos(grid_width, grid_height),
      snake: [rand_pos(grid_width, grid_height)],
      direction: nil,
      alive: true,
      height: grid_height,
      width: grid_width,
      log_file: log_file
    }
  end

  def update(model, msg) do
    case msg do
      {:event, %{key: key}} when key in @arrows ->
        %{model | direction: next_direction(key)}

      :tick ->
        move_snake(model)

      _ ->
        model
    end
  end

  def subscribe(_model) do
    Ratatouille.Runtime.Subscription.interval(100, :tick)
  end

  def render(%{snake: snake} = model) do
    view do
      panel(
        color: :green,
        padding: 0,
        height: :fill,
        title:
          "Snake! Grab the pellet, and avoid the walls! Score=#{length(snake)} (Press q to quit)"
      ) do
        render_grid(model)
      end
    end
  end

  def render_grid(%{alive: false}) do
    label(content: "Game Over")
  end

  def render_grid(%{alive: true} = model) do
    canvas(height: model.height, width: model.width) do
      pellet_cell(model)
      snake_cells(model)
    end
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

  defp next_direction(@up), do: :up
  defp next_direction(@down), do: :down
  defp next_direction(@left), do: :left
  defp next_direction(@right), do: :right

  defp move_snake(model) do
    next_snake =
      Enum.map(model.snake, fn {x, y} ->
        case model.direction do
          :up -> {x, y - 1}
          :down -> {x, y + 1}
          :right -> {x + 1, y}
          :left -> {x - 1, y}
          _ -> {x, y}
        end
      end)

    %{model | snake: next_snake}
  end
end
