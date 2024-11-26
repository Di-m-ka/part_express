create table "user" (
    id int,
    email varchar(64),
    name varchar (256),
    token varchar (32),
    is_deleted int
);
comment on table "user" is 'Пользователи в системы';
comment on column "user".id is 'Уникальный идентификатор пользователя';
comment on column "user".email is 'Логин и он же email пользователя';
comment on column "user".name is 'Ник пользователя';
comment on column "user".token is 'Захэшированный пароль пользователя';
insert into "user" (id, email, name, token) values (1, 'admin@example.ru', 'Garage 241', 'kjshdugfisubk');

create sequence user_seq  AS int  INCREMENT  BY 1  START 10 NO CYCLE OWNED BY "user".id;
ALTER TABLE  "user" ADD CONSTRAINT user_pk primary key (id);
ALTER TABLE  "user" ADD CONSTRAINT user_uq_email unique (email);
ALTER TABLE  "user" ADD CONSTRAINT user_uq_name unique (name);
ALTER TABLE "user"  ALTER COLUMN email SET NOT NULL;
ALTER TABLE "user"  ALTER COLUMN name SET NOT NULL;

CREATE OR REPLACE function user_create (p_email "user".email%TYPE, p_name "user".name%TYPE, p_token "user".token%TYPE) returns int AS $$
       DECLARE v_id int;
        BEGIN
               insert into "user" (email, name, token) values (p_email, p_name, p_token)  RETURNING id into v_id;
               RETURN v_id;
        END;
$$ LANGUAGE plpgsql;

create function user_update (id, email , name, token );
create function user_delete (id);

create table user_log (
    id int,
    email varchar(64),
    name varchar (256),
    token varchar (32),
    is_deleted int,
    log_date timestamp (0),
    log_type char(1),
    changed_by int);

CREATE OR REPLACE FUNCTION user_log_fn()
RETURNS trigger AS $body$
BEGIN
   if (TG_OP in ('INSERT','UPDATE')) then
       INSERT INTO user_log (
            id,
            email,
            name ,
            token ,
            is_deleted,
            log_date ,
            log_type ,
            changed_by
       )
       VALUES(
           NEW.id,
           NEW.email,
           NEW.name,
           NEW.token,
           NEW.is_deleted,
           CURRENT_TIMESTAMP,
           left(TG_OP,1),
           current_setting('var.logged_user')
       );
       RETURN NEW;
   else
       INSERT INTO user_log (
            id,
            email,
            name ,
            token ,
            is_deleted,
            log_date ,
            log_type ,
            changed_by
       )
       VALUES(
           OLD.id,
           OLD.email,
           OLD.name,
           OLD.token,
           OLD.is_deleted,
           CURRENT_TIMESTAMP,
           left(TG_OP,1),
           current_setting('var.logged_user')
       );
       RETURN OLD;
   end if;
END;
$body$
LANGUAGE plpgsql;

CREATE TRIGGER user_log_tr
AFTER INSERT OR UPDATE OR DELETE ON "user"
FOR EACH ROW EXECUTE FUNCTION user_log_fn();

create table "role"
(
    id int,
    name varchar(64),
    description text
);
comment on table role is 'Роли в системе';
comment on column role.id is 'Уникальный идентификатор роли';
comment on column role.name is 'Наименование роли';
comment on column role.description is 'Описание роли';
insert into role (id, name, description) values (1, 'Администратор', 'Полный доступ к функционалу сайта');
insert into role (id, name, description) values (2, 'Склад', 'Управляет комплектацией запчастей на складе');
insert into role (id, name, description) values (3, 'Сборщик', 'Изготавливает продукт из запчастей');
ALTER TABLE role ADD CONSTRAINT role_pk primary key (id);
ALTER TABLE role ALTER COLUMN name SET NOT NULL;
create sequence role_seq  AS int  INCREMENT  BY 1  START 10 NO CYCLE OWNED BY role.id;

create table user_x_role
(
    user_id int,
    role_id int
);
comment on table user_x_role is 'Принадлежность пользователя роли';
comment on column user_x_role.user_id is 'Уникальный идентификатор пользователя';
comment on column user_x_role.role_id is 'Уникальный идентификатор роли';
insert into user_x_role (user_id, role_id) values (1, 1);
ALTER TABLE user_x_role ADD CONSTRAINT user_x_role_pk primary key (user_id,role_id);
ALTER TABLE user_x_role ADD CONSTRAINT user_fk_user_id foreign key (user_id) references "user" (id) on delete   no action;
ALTER TABLE user_x_role ADD CONSTRAINT user_fk_role_id foreign key (role_id) references "role" (id) on delete   no action;

create table object_type (
    id int,
    name varchar (32),
    description varchar (256)
);
comment on table object_type is 'Обьекты в системе';
insert into object_type (id, name, description) values (1, 'order', 'Заказ на изготовление продукта');

create table state(
    id int,
    object_type_id int,
    name varchar (64)
);
comment on table state is 'Статусы';
comment on column state.id is 'Уникальный идентификатор статуса';
comment on column state.object_type_id is 'Принадлежность статуса объекту';
comment on column state.name is 'Наименование статуса';
insert into state (id, object_type_id, name) values (1, 1, 'В очереди на изготовление');
insert into state (id, object_type_id, name) values (2, 1, 'В работе');
insert into state (id, object_type_id, name) values (3, 1, 'Изготовлен');

create table product (
    id int,
    name varchar (32)
);
comment on table product is 'Продукт';
comment on column state.id is 'Уникальный идентификатор продукта';
comment on column state.name is 'Наименование продукта';
insert into product (id, name) values (1, 'Муфельная печь');
insert into product (id, name) values (2, 'Ребризер');

create table part
(
    id bigint,
    name varchar (32)
);
comment on table part is 'Запчасть';
comment on column state.id is 'Уникальный идентификатор запчасти';
comment on column state.name is 'Наименование запчасти';

insert into part (id, name) values (1, 'Кирпич шамотный тип 1');
insert into part (id, name) values (2, 'Нихромовая нить');
insert into part (id, name) values (3, 'Стальной лист');
insert into part (id, name) values (4, 'Баллон алюминиевый 2л кислород');
insert into part (id, name) values (5, 'Баллон алюминиевый 2л инфлюент');
insert into part (id, name) values (6, 'Картридж едкий натр 2л');
insert into part (id, name) values (7, 'Контроллер дыхательной смеси');
insert into part (id, name) values (8, 'Противолегкое');

create table unit(
    id int,
    name varchar (32)
);
comment on table unit is 'диница измерения';
insert into unit (id, name) values (1, 'шт');
insert into unit (id, name) values (2, 'кг');
insert into unit (id, name) values (3, 'м');
insert into unit (id, name) values (4, 'м кв.');

create table product_x_part
        (
            id bigint,
            product_id int,
            part_id int,
            count numeric,
            unit_id int
        );
comment on table product_x_part is 'Составляющие продукта';
comment on column product_x_part.id is 'Уникальный идентификатор составляющей';
comment on column product_x_part.product_id is 'Ссылка на продукт';
comment on column product_x_part.part_id is 'Ссылка на запчасть';
comment on column product_x_part.count is 'Расчетное кол-во запчастей на продукт';
comment on column product_x_part.unit_id is 'Расчетная единица измерения кол-ва запчастей';

create table "order"
(
    id bigint,
    user_id int,
    state_id int,
    product_id int
);
comment on table "order" is 'Заказ на изготовление';
comment on column "order".id is 'Уникальный идентификатор заказа';
comment on column "order".user_id is 'Ссылка на изготовителя продукта';
comment on column "order".state_id is 'Ссылка на статус изготовления продукта';
comment on column "order".product_id is 'Ссылка на продукт';

create table order_hist (
    id bigint,
    user_id int,
    state_id int,
    product_id int,
    log_date timestamp (0),
    log_type char(1),
    changed_by int
);
comment on table order_hist is 'История изменения заказа';

create table warehouse(
    id int,
    name varchar (128)
);
comment on table order_hist is 'Склад';
insert into warehouse (id, name) values (1, 'Основной склад');

create table part_x_warehouse(
    part_id bigint,
    warehouse_id int,
    count numeric,
    unit_id int
);
comment on table order_hist is 'Наличие на складе';

create table part_x_warehouse_hist (
    part_id bigint,
    warehouse_id int,
    count numeric,
    unit_id int,
    log_date timestamp (0),
    log_type char(1),
    changed_by int
);
comment on table part_x_warehouse_hist is 'История изменения склада';

create table image (
    id bigint,
    object_id bigint,
    object_type_id int,
    blob bytea,
    path varchar(32)
);
comment on table image is 'Изображения';