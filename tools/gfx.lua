local addonInfo, privateVars = ...

---------- init namespace ---------
if not LibEKL then LibEKL = {} end
if not LibEKL.Tools then LibEKL.Tools = {} end
if not LibEKL.Tools.Gfx then LibEKL.Tools.Gfx = {} end

--- Konvertiert eine 3x3-Matrix in das Format, das Canvas:SetShape erwartet (flaches Array mit 6 Werten).
-- @param matrix3x3 Die 3x3-Matrix als verschachteltes Table.
-- @return Flaches Array mit den ersten beiden Zeilen der Matrix.
function LibEKL.Tools.Gfx.MatrixToCanvasTransform(matrix3x3)
  return {
    matrix3x3[1][1], matrix3x3[1][2], matrix3x3[1][3],
    matrix3x3[2][1], matrix3x3[2][2], matrix3x3[2][3]
  }
end

--- Multipliziert zwei 3x3-Matrizen.
-- @param a Erste Matrix.
-- @param b Zweite Matrix.
-- @return Ergebnis der Matrizenmultiplikation als 3x3-Matrix.
function LibEKL.Tools.Gfx.multiplyMatrices(a, b)
  local result = {
    {0, 0, 0},
    {0, 0, 0},
    {0, 0, 1}  -- Die dritte Zeile bleibt immer [0, 0, 1] für 2D-Transformationen
  }

  for i = 1, 2 do
    for j = 1, 3 do
      for k = 1, 3 do
        result[i][j] = result[i][j] + a[i][k] * b[k][j]
      end
    end
  end

  return result
end

--- Erstellt eine Transformationsmatrix für Rotation um den Mittelpunkt eines Frames.
-- @param frame Das UI-Element (Frame oder Canvas).
-- @param angle Rotationswinkel in Radiant.
-- @param scale Skalierungsfaktor (optional).
-- @return Transformationsmatrix im Format für Canvas:SetShape (flaches Array mit 6 Werten).
function LibEKL.Tools.Gfx.Rotate(frame, angle, scale)

  --m:Translate(midx,midy)
  --m:Rotate(angle)
  --m:Translate(-midx,-midy)

  local midx = frame:GetWidth() / 2
  local midy = frame:GetHeight() / 2

  -- 1. Translation zum Mittelpunkt
  local translationToCenter = {
    {1, 0, midx},
    {0, 1, midy},
    {0, 0, 1}
  }

  -- 2. Rotation
  local rotationMatrix = {
    {math.cos(angle), math.sin(angle), 0},
    {-math.sin(angle), math.cos(angle), 0},
    {0, 0, 1}
  }

    -- 1. Translation zum Mittelpunkt
  local translationToCenter2 = {
    {1, 0, -midx},
    {0, 1, -midy},
    {0, 0, 1}
  }

  -- 3. Skalierung (falls gewünscht)
  local scaleMatrix = {
    {scale or 1, 0, 0},
    {0, scale or 1, 0},
    {0, 0, 1}
  }

  -- 4. Kombiniere die Matrizen in der richtigen Reihenfolge:
  -- Zuerst skalieren, dann rotieren, dann zum Mittelpunkt verschieben
  --local matrix3x3 = LibEKL.Tools.Gfx.multiplyMatrices(translationToCenter, LibEKL.Tools.Gfx.multiplyMatrices(rotationMatrix, scaleMatrix))
  local matrix1 = LibEKL.Tools.Gfx.multiplyMatrices(translationToCenter, rotationMatrix)
  local matrix2 = LibEKL.Tools.Gfx.multiplyMatrices(matrix1, translationToCenter2)

  -- 5. Konvertiere in das Format für Canvas:SetShape
  return LibEKL.Tools.Gfx.MatrixToCanvasTransform(matrix2)
end