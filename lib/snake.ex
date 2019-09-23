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

    grid_height = window.height - 2
    grid_width = window.width - 2

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
        %{model | direction: next_direction(model.direction, key_code_to_direction(key))}

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

  defp next_direction(:up, :down), do: :up
  defp next_direction(:down, :up), do: :down
  defp next_direction(:left, :right), do: :left
  defp next_direction(:right, :left), do: :right
  defp next_direction(curr_direction, key_direction), do: key_direction

  defp key_code_to_direction(@up), do: :up
  defp key_code_to_direction(@down), do: :down
  defp key_code_to_direction(@left), do: :left
  defp key_code_to_direction(@right), do: :right

  defp move_snake(model) do
    [head | tail] = model.snake
    next_head = next_pos(head, model.direction)

    cond do
      out_of_bounds(model, next_head) ->
        %{model | alive: false}

      next_head == model.pellet ->
        next_pellet = rand_pos(model.width, model.height)
        %{model | pellet: next_pellet, snake: [next_head | model.snake]}

      true ->
        %{model | snake: [next_head | Enum.drop(model.snake, -1)]}
    end
  end

  defp next_pos({x, y}, :up), do: {x, y - 1}
  defp next_pos({x, y}, :down), do: {x, y + 1}
  defp next_pos({x, y}, :left), do: {x - 1, y}
  defp next_pos({x, y}, :right), do: {x + 1, y}
  defp next_pos({x, y}, _), do: {x, y}

  defp out_of_bounds(model, {head_x, head_y}) do
    head_x < 0 || head_x >= model.width || head_y < 0 || head_y >= model.height
  end
end
