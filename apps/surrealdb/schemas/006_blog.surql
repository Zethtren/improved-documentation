DEFINE TABLE blog_post SCHEMAFULL;
DEFINE FIELD title ON TABLE blog_post TYPE string;
DEFINE FIELD slug ON TABLE blog_post TYPE string;
DEFINE FIELD content ON TABLE blog_post TYPE string;
DEFINE FIELD published ON TABLE blog_post TYPE datetime DEFAULT time::now();
DEFINE FIELD tags ON TABLE blog_post TYPE array DEFAULT [];
DEFINE FIELD draft ON TABLE blog_post TYPE bool DEFAULT true;

DEFINE INDEX idx_blog_slug ON TABLE blog_post COLUMNS slug UNIQUE;
