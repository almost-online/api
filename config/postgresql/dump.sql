CREATE TABLE "user" (
	"id" serial NOT NULL,
	"password" varchar(64) NOT NULL,
	"email" varchar(256) NOT NULL,
	"role_id" int NOT NULL,
	CONSTRAINT user_pk PRIMARY KEY ("id")
) WITH (
  OIDS=FALSE
);



CREATE TABLE "role" (
	"id" serial NOT NULL,
	"name" varchar(64) NOT NULL,
	CONSTRAINT role_pk PRIMARY KEY ("id")
) WITH (
  OIDS=FALSE
);
