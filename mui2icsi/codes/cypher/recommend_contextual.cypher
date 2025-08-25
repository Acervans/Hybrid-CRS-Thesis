// Recommend items based on context, popularity, and authority.
// Parameters:
//   - User ID: 'user_A'
//   - Item Properties (Context): category = 'Books', genre = 'Sci-Fi'
//   - Seen Items: ['item_101', 'item_205'] (Items to exclude)
//   - MIN_R: 10 (Minimum ratings for an item to be considered reliable)
//   - Global Average Rating: 3.5

// Step 1: Find all items that match the desired contextual properties.
// We also filter out items the user has already interacted with.
MATCH (itm:Item)
WHERE (itm.category = 'Books' OR itm.genre = 'Sci-Fi')
  AND NOT itm.item_id IN ['item_101', 'item_205']

// Step 2: For each matched item, calculate its average rating and rating count.
// OPTIONAL MATCH is used because an item might not have any ratings yet.
OPTIONAL MATCH ()-[r:RATED]->(itm)
WITH itm, avg(r.rating) AS avgRating, count(r) AS cnt

// Step 3: Calculate the three scores for ranking.
// The final ranking will be done in the application layer after normalizing these scores.
RETURN
    itm.item_id AS itemId,

    // Score 1: Context Score. A simple count of how many desired properties match.
    (CASE WHEN itm.category = 'Books' THEN 1 ELSE 0 END + CASE WHEN itm.genre = 'Sci-Fi' THEN 1 ELSE 0 END) AS contextScore,

    // Score 2: Weighted Score. This is a smoothed average rating.
    // It pulls the item's average rating towards the global average,
    // which gives more reliable scores for items with few ratings.
    ((cnt * avgRating) + (10 * 3.5)) / (cnt + 10) AS weightedScore,

    // Score 3: PageRank. A measure of the item's authority or importance in the graph.
    // This is pre-calculated and stored as a node property.
    itm.pagerank AS pageRank
