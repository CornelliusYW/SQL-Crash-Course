-- Create indexes for MySQL
CREATE INDEX idx_posts_name ON posts(name);
CREATE INDEX idx_posts_newsletter_published ON posts(newsletter_id, published_at);
CREATE INDEX idx_interactions_post ON interactions(post_id);
CREATE INDEX idx_interactions_covered ON interactions(post_id, points, datetime);