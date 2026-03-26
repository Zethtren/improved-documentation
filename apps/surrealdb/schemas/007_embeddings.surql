DEFINE TABLE blog_embedding SCHEMAFULL;
DEFINE FIELD blog_post_id ON TABLE blog_embedding TYPE string;
DEFINE FIELD embedding ON TABLE blog_embedding TYPE array;
DEFINE FIELD content_hash ON TABLE blog_embedding TYPE string;

DEFINE TABLE recommended_link SCHEMAFULL;
DEFINE FIELD blog_post_id ON TABLE recommended_link TYPE string;
DEFINE FIELD url ON TABLE recommended_link TYPE string;
DEFINE FIELD title ON TABLE recommended_link TYPE string;
DEFINE FIELD description ON TABLE recommended_link TYPE option<string>;
DEFINE FIELD source ON TABLE recommended_link TYPE string DEFAULT 'ai-generated';
DEFINE FIELD relevance_score ON TABLE recommended_link TYPE option<float>;
DEFINE FIELD fetched_at ON TABLE recommended_link TYPE datetime DEFAULT time::now();
