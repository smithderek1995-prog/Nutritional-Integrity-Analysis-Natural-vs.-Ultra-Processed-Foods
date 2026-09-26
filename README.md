Nutritional Integrity Analysis: Natural vs. Ultra-Processed Foods

Project Overview

<img width="1325" height="740" alt="Nutrition Facts Screenshot" src="https://github.com/user-attachments/assets/55a2a778-dc20-480b-bf2a-3dfc81a6d9a6" />

This project analyzes a 644,000-row USDA nutritional database to visually distinguish the nutritional profiles of "Whole & Natural" foods against "Processed & Man-Made" alternatives. Designed with half-marathon and distance race preparation in mind, the dashboard highlights hidden industrial additives (Sodium, Added Sugars) and stripped essentials (Fiber, Potassium) while intentionally keeping endurance fuel metrics (Carbohydrates, Calories) neutral.

Tech Stack Used:

SQL (Google BigQuery): Data extraction, filtering, and relational joins.

Power BI & Power Query (M): Data modeling, ETL, and upstream classification.

DAX: Dynamic measures and custom conditional formatting.

AI / LLMs: Leveraged for rapid text-parsing of large categorical datasets and M code optimization.
_______________________________________________________________________________________
Phase 1: Data Extraction & Relational Modeling (SQL)

September 21 - 22, 2026

The initial data exploration and joining were performed in Google BigQuery. I utilized INNER JOINs to merge the core food descriptions with their specific nutrient values, intentionally filtering out blank or zero-logged foods to maintain data integrity.

SQL

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
_________________________________________________________________________________________
Phase 2: ETL & Upstream Optimization (Power Query)

September 23 - 25, 2026

Upon loading the data into Power BI, I discovered deep inconsistencies in the naming conventions of the USDA dataset. Writing a massive DAX SWITCH statement to categorize thousands of rows caused severe performance issues.

Solution: I created a physical mapping table and pushed the classification logic upstream into Power Query. I utilized AI to rapidly parse and categorize thousands of unique food descriptions into logical buckets. To prevent bogging down the engine by scanning the massive database multiple times, I optimized the M code to scan each row exactly once, grab both mapping columns using a temporary Record, and expand them instantly.

let
    // ... [Source and connection steps] ...
    
    // 1. Buffer the Excel table exactly ONCE for performance
    BufferedMap = Table.Buffer(Table1),

    // 2. Scan the row ONCE and grab BOTH columns using a temporary Record
    AddedMappingRecord = Table.AddColumn(#"Sorted Rows", "MappingData", 
        (row) => 
            let 
                MatchedRow = Table.SelectRows(BufferedMap, each Text.Contains(row[food_name], [Keyword], Comparer.OrdinalIgnoreCase))
            in 
                if Table.IsEmpty(MatchedRow) then 
                    [#"Food Category" = "Other/Mixed", #"Processing Level" = "Other/Mixed"] 
                else 
                    [#"Food Category" = MatchedRow{0}[Food Category], #"Processing Level" = MatchedRow{0}[Processing Level]]
    ),

    // 3. Expand the Record into the two final columns instantly
    ExpandedColumns = Table.ExpandRecordColumn(AddedMappingRecord, "MappingData", {"Food Category", "Processing Level"})
in
    ExpandedColumns
__________________________________________________________________________________________
Phase 3: Analytical Problem Solving (EDA)

September 25, 2026

During exploratory data analysis and visual design, I encountered and solved two major data traps:

The Unit Mismatch (Apples to Apples): When building the Scatter Plot to compare Sodium to Sugar, I identified a severe visual skew because Sugar was measured in grams (g) and Sodium in milligrams (mg). I created a DAX measure to convert Sodium to grams (DIVIDE by 1000), locking the X and Y axes to a true 1:1 weight ratio. This revealed just how disproportionate industrial sugar additives are by volume.

The Fiber Paradox (Contextual Averages): Initially, "Whole & Natural Foods" appeared to have lower average fiber than processed foods. By interrogating the data, I identified that the natural category was heavily anchored by raw meats (0g fiber) and water-dense fresh produce, whereas processed foods (like bran cereals and dehydrated bars) had artificially concentrated nutrients. Building interactive slicers allowed the end-user to filter by specific food groups, isolating variables and revealing the true data story.
__________________________________________________________________________________________
Phase 4: Dashboard Design & Advanced DAX

September 25, 2026

The front-end design required custom solutions to tell the right story. Standard Power BI conditional formatting could not handle a Star Schema where all nutrient values lived in a single amount column.

Dynamic Conditional Formatting:

I wrote a dynamic DAX measure utilizing the UK Food Standards Agency Traffic Light thresholds. Because this tool evaluates endurance training fuel, core macros (Carbohydrates, Protein, Fat, Calories) are treated as essential baseline metrics rather than negative health indicators. The code intentionally excludes these macros from the formatting rules, isolating the red/yellow/green alerts strictly to industrial additives (Sodium, Sugar, Trans Fats) and stripped essentials (Fiber, Potassium).

Nutrient Traffic Light = 
VAR CurrentNutrient = MAX('nutrient'[name])
VAR CurrentValue = SUM('food_nutrition'[amount])

RETURN 
SWITCH(TRUE(),
    // Sodium (Lower is better)
    CurrentNutrient = "Sodium, Na" && CurrentValue > 600, "#FFB3B3", // Red
    CurrentNutrient = "Sodium, Na" && CurrentValue >= 120, "#FFFFB3", // Yellow
    CurrentNutrient = "Sodium, Na" && CurrentValue >= 0, "#B3FFB3", // Green
    
    // Sugars (Lower is better)
    CurrentNutrient = "Sugars, total" && CurrentValue > 22.5, "#FFB3B3",
    CurrentNutrient = "Sugars, total" && CurrentValue >= 5, "#FFFFB3",
    CurrentNutrient = "Sugars, total" && CurrentValue >= 0, "#B3FFB3",
    
    // Trans Fat (Lower is better)
    CurrentNutrient = "Fatty acids, total trans" && CurrentValue > 0, "#FFB3B3",
    CurrentNutrient = "Fatty acids, total trans" && CurrentValue = 0, "#B3FFB3",
    
    // Fiber (Higher is better)
    CurrentNutrient = "Fiber, total dietary" && CurrentValue < 3, "#FFB3B3",
    CurrentNutrient = "Fiber, total dietary" && CurrentValue <= 6, "#FFFFB3",
    CurrentNutrient = "Fiber, total dietary" && CurrentValue > 6, "#B3FFB3",
    
    // Potassium (Higher is better)
    CurrentNutrient = "Potassium, K" && CurrentValue < 150, "#FFB3B3",
    CurrentNutrient = "Potassium, K" && CurrentValue <= 300, "#FFFFB3",
    CurrentNutrient = "Potassium, K" && CurrentValue > 300, "#B3FFB3",
    
    // Core macros ignored to maintain neutral baseline
    BLANK()
)
Custom Sort Ordering:

To improve UX and narrative flow, I implemented a custom Sort By DAX column, forcing the matrix visual to cleanly separate uncolored baseline macros on the left from the color-coded processing indicators on the right.

Nutrient Sort Order = 
SWITCH('nutrient'[name],
    "Energy", 1,
    "Protein", 2,
    "Carbohydrate, by difference", 3,
    "Total lipid (fat)", 4,
    "Sodium, Na", 5,
    "Sugars, total", 6,
    "Fatty acids, total trans", 7,
    "Fiber, total dietary", 8,
    "Potassium, K", 9,
    10
)
