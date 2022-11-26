create table if not exists division
(
    id serial not null constraint division_pk primary key,
    "name"      varchar(100)             not null
);

create table if not exists department
(
    id serial not null constraint department_pk primary key,
    "name"      varchar(100)             not null
);

create table if not exists department_history
(
    id serial not null constraint department_history_pk primary key,
    department_id int4 references department(id) on update cascade on delete restrict,
    quantity   int4      default 0,
    avg_salary int8      default 0,
    "date"     timestamp default now()
);

create table if not exists role
(
    id serial not null constraint role_pk primary key,
    "name"      varchar(100)             not null
);

create table if not exists "user"
(
    id serial not null constraint user_pk primary key,
    uuid         char(28)                     not null,
    "name"       varchar(100)                 not null,
    email        varchar(100)                 not null,
    rights       varchar(20) default 'user'   not null,
    division_id  int4 references  division(id) on update cascade on delete restrict,
    department_id int4 references department(id) on update cascade on delete restrict,
    role_id      int4 references  role(id) on update cascade on delete restrict,
    fixed_salary float8 default 0             not null,
    active       bool default true            not null,
    birthday     timestamp default now()      not null,
    joined       timestamp default now()      not null,
    image        varchar(100) default ''      not null
);

create table if not exists team
(
    id serial not null constraint team_pk primary key,
    boss_id        int4 references "user"(id)     on update cascade on delete restrict not null,
    department_id  int4 references department(id) on update cascade on delete restrict,
    "name"        varchar(100)           not null,
    created       timestamp           default now()
);

create table if not exists team_history
(
    id         serial not null constraint team_history_pk primary key,
    team_id    int4 references team(id) on update cascade on delete restrict not null,
    quantity   int4      default 0,
    avg_salary int8      default 0,
    "date"     timestamp default now()
);

alter table if exists "user"
    add column if not exists team_id int4 references team(id) on update cascade on delete restrict;

create table if not exists team_joins
(
    id serial not null constraint team_joins_pk primary key,
    user_id       int4 references "user"(id)     on update cascade on delete restrict not null,
    team_id       int4 references team(id)       on update cascade on delete restrict not null,
    joined       timestamp           default now()
);

create table if not exists relation
(
    boss_id        int4 references "user"(id) on update cascade on delete restrict not null,
    subordinate_id int4 references "user"(id) on update cascade on delete restrict not null
);

create table if not exists events_history
(
    id serial   not null constraint events_history_pk primary key,
    author_id   int4 references "user"(id) on update cascade on delete restrict not null,
    subject_id  int4,
    related_to  varchar(100) default '' not null,
    description varchar(100) default '' not null,
    "date"      timestamp default now() not null
);

create table if not exists user_ambitions
(
    id serial   not null constraint user_ambitions_pk primary key,
    author_id   int4 references "user"(id) on update cascade on delete restrict not null,
    user_id     int4 references "user"(id) on update cascade on delete restrict not null,
    note        varchar(255)    default '' not null,
    created     timestamp default now()    not null
);

create table if not exists meeting
(
    id serial   not null constraint meeting_pk primary key,
    author_id   int4 references "user"(id) on update cascade on delete restrict not null,
    user_id     int4 references "user"(id) on update cascade on delete restrict not null,
    note        varchar(255)    default '' not null,
    "date"      timestamp default now()    not null,
    created     timestamp default now()    not null
);

create table if not exists user_note
(
    id serial   not null constraint user_note_pk primary key,
    author_id   int4 references "user"(id) on update cascade on delete restrict not null,
    user_id     int4 references "user"(id) on update cascade on delete restrict not null,
    note        varchar(255)    default '' not null,
    created     timestamp default now()    not null
);

create table if not exists dismissal
(
    id serial   not null constraint dismissal_pk primary key,
    author_id   int4 references "user"(id) on update cascade on delete restrict not null,
    user_id     int4 references "user"(id) on update cascade on delete restrict not null,
    note        varchar(255)    default '' not null,
    created     timestamp default now()    not null
);

create table if not exists vacation_type
(
    id serial not null constraint vacation_type_pk primary key,
    "type"    varchar(100)                not null
);

INSERT INTO vacation_type VALUES (1, 'Holiday');
INSERT INTO vacation_type VALUES (2, 'Sick leave');

create table if not exists user_vacation
(
    id serial   not null constraint user_vacation_pk primary key,
    user_id     int4 references "user"(id)        on update cascade on delete restrict not null,
    type_id     int4 references vacation_type(id) on update cascade on delete restrict not null,
    available   int4 default 0 not null,
    used        int4 default 0 not null
);

create table if not exists vacation_request
(
    id serial   not null constraint vacation_request_pk primary key,
    user_id     int4 references "user"(id)        on update cascade on delete restrict not null,
    type_id     int4 references vacation_type(id) on update cascade on delete restrict not null,
    start_date  timestamp default now()    not null,
    period      int4                       not null,
    description varchar(255)    default '' not null,
    status      boolean,
    created     timestamp    default now() not null
);

create table if not exists salary_history
(
    id serial   not null constraint salary_history_pk primary key,
    user_id     int4 references "user"(id) on update cascade on delete restrict not null,
    fixed_rate  float8 default 0        not null,
    mentorship  float8 default 0        not null,
    bonuses     float8 default 0        not null,
    another     float8 default 0        not null,
    sport       float8 default 0        not null,
    relocate    float8 default 0        not null,
    purchase    float8 default 0        not null,
    fees        float8 default 0        not null,
    total       float8                  not null,
    status      varchar(50)             not null,
    description varchar(255) default '' not null,
    created     timestamp default now() not null
);

create table if not exists salary_request
(
    id serial   not null constraint salary_request_pk primary key,
    salary_history_id     int4 references salary_history(id) on update cascade on delete restrict not null,
    pm_approve boolean,
    tm_approve boolean
);

create table if not exists relations
(
    id serial   not null constraint relations_pk primary key,
    structure   varchar(10000) default '' not null
);

create table if not exists hr_team_joins
(
    id serial not null constraint hr_team_joins_pk primary key,
    user_id       int4 references "user"(id)     on update cascade on delete restrict not null,
    team_id       int4 references team(id)       on update cascade on delete restrict not null,
    attached      timestamp           default now()
);

ALTER TABLE "user" ADD CONSTRAINT user_uuid UNIQUE (uuid);
ALTER TABLE division ADD CONSTRAINT division_name UNIQUE (name);
ALTER TABLE department ADD CONSTRAINT department_name UNIQUE (name);
ALTER TABLE role ADD CONSTRAINT role_name UNIQUE (name);
ALTER TABLE vacation_type ADD CONSTRAINT vacation_type_name UNIQUE (type);
