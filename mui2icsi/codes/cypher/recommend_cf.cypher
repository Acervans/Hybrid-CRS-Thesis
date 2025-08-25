// Goal: Recommend items based on the preferences of similar users (neighbors).
// Parameters:
//   - User ID: 'user_A'
//   - Min Rating for "Like": 3.0
//   - K (Neighbors): 10
//   - Top-N (Recommendations): 10
//   - Seen Items: ['item_101', 'item_205']
//   - Global Average Rating: 3.5

// --- Part 1: Find Top-K Similar Users (Neighbors) ---

// Step 1: Find a user (u1) and identify other users (u2) who have rated the same items (i).
MATCH (u1:User {user_id: 'user_A'})-[r1:RATED]->(i:Item)<-[r2:RATED]-(u2:User)
// We only consider items that both users "liked" (rating >= 3.0).
WHERE r1.rating >= 3.0 AND r2.rating >= 3.0 AND u1 <> u2

// Step 2: Count the number of co-rated items for each user (u2) to measure similarity.
WITH u2, count(i) AS sharedItems
// Order by the count to find the most similar users.
ORDER BY sharedItems DESC
// Limit to the top K neighbors.
LIMIT 10

// Step 3: Collect the IDs of these neighbors to use in the next stage.
WITH collect(u2.user_id) AS neighborIds

// --- Part 2: Recommend Items from Neighbors ---

// Step 4: Find all items that the neighbors liked.
MATCH (neighbor:User)-[r:RATED]->(i:Item)
WHERE neighbor.user_id IN neighborIds
  AND r.rating >= 3.0
  // Exclude items the target user has already seen.
  AND NOT i.item_id IN ['item_101', 'item_205']

// Step 5: Calculate a weighted score for each potential recommendation.
WITH i, avg(r.rating) AS avgRating, count(r) AS cnt
WITH i, ((cnt * avgRating) + (10 * 3.5)) / (cnt + 10) AS weightedScore

// Step 6: Return the top N recommended items, ordered by their score.
RETURN i.item_id AS recommendation, weightedScore
ORDER BY weightedScore DESC
LIMIT 10
