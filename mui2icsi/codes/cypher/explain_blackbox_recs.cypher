// Goal: Find items liked by the user that share a specific property
//       (e.g., 'category', 'brand') with the recommended item.
//
// This query runs in a loop for each property in `shared_props`.
// Parameters:
//   - $user_id: The ID of the target user (e.g., 'user_A').
//   - $min_rating: The minimum rating to consider an item "liked" (e.g., 4.0).
//   - $top_feat_exp: The max number of examples to return (e.g., 5).
//   - The WHERE clause (i.{property} = {value}) is built dynamically.

// Case 1: Regular property (exact match)
MATCH (u:User {user_id: $user_id})-[r:RATED]->(i:Item)
// The condition below is constructed by the Python code.
// For example, if the recommended item's category is 'Books',
// the condition becomes: i.category = 'Books'
WHERE r.rating >= $min_rating AND i.brand = 'Nintendo'
// Return the shared property value and the full item node.
// The application uses this to construct the explanation string.
RETURN i.brand AS value, i
ORDER BY r.rating DESC
LIMIT $top_feat_exp;

// Case 2: Sequential property (contains match)  
MATCH (u:User {user_id: $user_id})-[r:RATED]->(i:Item)
WHERE r.rating >= $min_rating AND (i.category CONTAINS 'Action' OR i.category CONTAINS 'Adventure')
RETURN i.category AS value, i
ORDER BY r.rating DESC
LIMIT $top_feat_exp;


// Goal: Find social proof by identifying "similar users" who also liked the recommended item.
// Path: (Target User)-[:LIKED]->(Shared Item)<-[:LIKED]-(Similar User)-[:LIKED]->(Recommended Item)
//
// Parameters:
//   - $user_id: The ID of the target user (e.g., 'user_A').
//   - $item_id: The ID of the recommended item (e.g., 'item_550').
//   - $min_rating: The rating threshold for a "liked" item (e.g., 3.0).
//   - $similar_item_ids: A list of item IDs found in the Feature Similarity step.
//   - $top_collab_exp: The max number of collaborative explanations (e.g., 5).

// Step 1: Match the full 3-hop collaborative path.
MATCH (u:User {user_id: $user_id})-[r1:RATED]->(i:Item)<-[r2:RATED]-(u2:User)-[r3:RATED]->(rec:Item {item_id: $item_id})
WHERE r1.rating >= $min_rating
  AND r2.rating >= $min_rating
  AND r3.rating >= $min_rating

// Step 2: For each shared item 'i', count the supporting users and check if 'i'
// was also found in the feature similarity step (passed in as a parameter).
WITH
  count(DISTINCT u2) AS numUsers,
  i AS shared_item,
  (i.item_id IN $similar_item_ids) AS sharesProp

// Step 3: Return the evidence, prioritizing paths that also have shared features.
RETURN
  numUsers,
  shared_item,
  sharesProp
ORDER BY
  sharesProp DESC, // Prioritize items that also explain via feature similarity
  numUsers DESC
LIMIT $top_collab_exp


// Goal: Calculate the average rating and total number of ratings for the recommended item.
//
// Parameters:
//   - $item_id: The ID of the recommended item (e.g., 'item_550').

// Find all RATED relationships pointing to the recommended item.
MATCH (:User)-[r:RATED]->(rec:Item {item_id: $item_id})

// Use aggregation to get the average and count.
RETURN
  avg(r.rating) AS avgRating,
  count(r) AS totalRatings
