SELECT 
  f.description AS food_name,
  n.name AS nutrient_name,
  fn.amount,
  n.unit_name
FROM `project-3b042aa2-b02e-457a-973.Food.food` AS f
-- First join: Connect the food to its raw nutrient amounts
INNER JOIN `project-3b042aa2-b02e-457a-973.Food.food_nutrition` AS fn
  ON f.fdc_id = fn.fdc_id
-- Second join: Connect the nutrient ID to its plain-English name
INNER JOIN `project-3b042aa2-b02e-457a-973.Food.nutrient` AS n
  ON fn.nutrient_id = n.id
ORDER BY 
  food_name, 
  nutrient_name
