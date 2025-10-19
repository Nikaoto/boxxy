local ffi = require("ffi")

ffi.cdef[[
typedef struct TSLanguage TSLanguage;
typedef struct TSParser TSParser;
typedef struct TSTree TSTree;
typedef struct TSNode {
  const void *id;
  const void *tree;
  uint32_t context[4];
} TSNode;

TSParser *ts_parser_new(void);
void ts_parser_delete(TSParser *);
void ts_parser_set_language(TSParser *, const TSLanguage *);
TSTree *ts_parser_parse_string(TSParser *, const TSTree *, const char *, uint32_t);
TSNode ts_tree_root_node(const TSTree *);
const char *ts_node_type(TSNode);
uint32_t ts_node_child_count(TSNode);
TSNode ts_node_child(TSNode, uint32_t);

const TSLanguage *tree_sitter_c(void);
uint32_t ts_node_start_byte(TSNode);
uint32_t ts_node_end_byte(TSNode);
TSNode ts_node_child_by_field_name(TSNode, const char *, uint32_t);
]]

local libpath = love.filesystem.getSourceBaseDirectory()
local lib = ffi.load(libpath .. "/src/libtree-sitter.so")
local lang = ffi.load(libpath .. "/src/tree-sitter-c.so")

function get_fn_name(ctx, def_node)
   if not def_node then return nil end

   -- function_definition -> function_declarator -> declarator -> identifier
   local decl = lib.ts_node_child_by_field_name(def_node, "declarator", 10)

   for i=0, lib.ts_node_child_count(decl)-1 do
      local child = lib.ts_node_child(decl, i)
      if ffi.string(lib.ts_node_type(child)) == "identifier" then
         local start_byte = lib.ts_node_start_byte(child)
         local end_byte = lib.ts_node_end_byte(child)
         local name = ctx.src:sub(start_byte+1, end_byte)
         return name
      end
   end

   return nil
end

function new_conn()
   return {
      line = 0,
      char = 0,
      fn_id = 0,
      fn = nil,
   }
end

function new_fn()
   return {
      id = 1,
      file = "default",
      text_string = "",
      line_count = 0,
      connections = {},
      start_byte = 0,
      end_byte = 0,
   }
end

function find_fn_by_name(ctx, name)
   for i, fn in ipairs(ctx.fns) do
      if fn.name == name then
         return fn
      end
   end

   return nil
end

function make_nodes(ctx, node)
   local node_type = ffi.string(lib.ts_node_type(node))

   local pop_nest = false

   if node_type == "function_definition" then
      local start_byte = lib.ts_node_start_byte(node)
      local end_byte = lib.ts_node_end_byte(node)
      local body_text  = ctx.src:sub(start_byte + 1, end_byte)
      local name = get_fn_name(ctx, node)

      local fn = new_fn()
      fn.id = ctx.scope_id
      fn.text_string = body_text
      fn.name = name
      fn.file = ctx.file
      fn.line_count = string.nmatch(body_text, "\n")
      fn.start_byte = start_byte
      fn.end_byte = end_byte

      ctx.scope_id = ctx.scope_id + 1
      table.insert(ctx.fns, fn)

      table.insert(ctx.nesting, fn)
      pop_nest = true         
   elseif node_type == "call_expression" then
      local func_node = lib.ts_node_child(node, 0)  -- usually the function identifier
      local start_byte = lib.ts_node_start_byte(func_node)
      local end_byte   = lib.ts_node_end_byte(func_node)
      local name = ctx.src:sub(start_byte+1, end_byte)
      local fn = find_fn_by_name(ctx, name)
      if fn then
         local conn = new_conn()
         conn.fn = fn
         conn.fn_id = fn.id
         conn.char = 1
         local caller_fn = ctx.nesting[#ctx.nesting]
         local body_part = ctx.src:sub(end_byte - caller_fn.start_byte+1, end_byte)
         conn.line = string.nmatch(body_part, "\n") + 1
         local match = body_part:match("\n[^\n]+$")
         if match then
            conn.char = #match - 1
         else
            conn.char = #body_part
         end

         table.insert(caller_fn.connections, conn)
      end
   end

   for i=0, lib.ts_node_child_count(node) - 1 do
      make_nodes(ctx, lib.ts_node_child(node, i))
   end

   if pop_nest then
      table.remove(ctx.nesting)
   end
end

function make_ctx(src)
   return {
      src = src,
      file = "main.c",
      scope_id = 1,
      scope = {},
      nesting = {},
   }
end

function fill_scope(ctx, node)
   if ffi.string(lib.ts_node_type(node)) == "function_definition" then
      local name = get_fn_name(ctx, node)
      if name then
         ctx.scope[name] = (ctx.scope[name] or 0) + 1
      end
   end

   -- Recurse
   for i = 0, lib.ts_node_child_count(node)-1 do
      fill_scope(ctx, lib.ts_node_child(node, i))
   end
end


function make_state_from_dir(dir)
   local parser = lib.ts_parser_new()
   lib.ts_parser_set_language(parser, lang.tree_sitter_c())

   local ctx = make_ctx([[
// Allocates new Buffer and its data
Buffer*
new_buf(size_t data_size)
{
    Buffer *b = xmalloc(sizeof(Buffer));
    b->data = xmalloc(data_size);
    b->n_alloc = data_size;
    b->n_items = 0;
    return b;
}

// Only allocates the data of the Buffer
Buffer*
init_buf(Buffer *b, size_t data_size)
{
    b->data = xmalloc(data_size);
    b->n_alloc = data_size;
    b->n_items = 0;
    return b;
}

void
free_buf(Buffer *b)
{
    if (!b) return;
    if (b->data) free(b->data);
    free(b);
}

// Free all parts of a Buffer
void
free_buf_parts(Buffer *b)
{
    free(b->data);
}

void
buf_grow(Buffer *b, size_t min_growth)
{
    size_t new_size = b->n_alloc + MAX(min_growth, BUFFER_GROWTH);
    char *ptr = xrealloc(b->data, new_size);
    b->n_alloc = new_size;
    b->data = ptr;
}

// Push one byte into buffer's data, growing it if necessary.
// Return 0 on fail.
// Return 1 on success.
void
buf_push(Buffer *b, char c)
{
    if (b->n_items + 1 > b->n_alloc) {
        buf_grow(b, 1);
    }
    b->data[b->n_items] = c;
    b->n_items++;
}

// Append n bytes from src to buffer's data, growing it if necessary.
void
buf_append(Buffer *b, char *src, size_t n)
{
    if (n == 0) return;

    if (b->n_items + n > b->n_alloc) {
        buf_grow(b, n);
    }

    memcpy(b->data + b->n_items, src, n);
    b->n_items += n;
}

// Does not copy the null terminator
void
buf_append_str(Buffer *b, char *str)
{
    buf_append(b, str, strlen(str));
}

// Does not copy the null terminator
void
buf_append_buf(Buffer *dest, Buffer *src)
{
    if (src->n_items == 0) return;

    if (dest->n_items + src->n_items > dest->n_alloc) {
        buf_grow(dest, src->n_items);
    }

    memcpy(dest->data + dest->n_items, src->data, src->n_items);
    dest->n_items += src->n_items;
}

// Does not copy the null terminator
int
buf_sprintf(Buffer *buf, char *fmt, ...)
{
    va_list fmtargs;
    int len;

    // Determine formatted length
    va_start(fmtargs, fmt);
    len = vsnprintf(NULL, 0, fmt, fmtargs);
    va_end(fmtargs);
    len++;

    // Grow buffer if necessary
    if (buf->n_items + len > buf->n_alloc)
        buf_grow(buf, len);

    va_start(fmtargs, fmt);
    vsnprintf(buf->data + buf->n_items, len, fmt, fmtargs);
    va_end(fmtargs);

    // Exclude the null terminator at the end
    buf->n_items += len - 1;

    return len - 1;
}

// Return -1 on fopen error
// Return 0 on read error
// Return 1 on success
int
buf_append_file_contents(Buffer *buf, File *f, char *path)
{
    if (f->size == 0)
        return 1;

    if (buf->n_items + f->size > buf->n_alloc)
        buf_grow(buf, f->size);

    FILE *fp = fopen(path, "r");
    if (!fp) {
        perror("fopen()");
        return -1;
    }

    while (1) {
        size_t bytes_read = fread(buf->data + buf->n_items, 1, f->size, fp);
        buf->n_items += bytes_read;
        if (bytes_read < (size_t) f->size) {
            if (ferror(fp)) {
                fprintf(stdout, "Error when freading() file %s\n", path);
                fclose(fp);
                return 0;
            }
            // EOF
            fclose(fp);
            return 1;
        }
    }

    fclose(fp);
    return 1;
}

void
print_buf_ascii(FILE *stream, Buffer *buf)
{
    if (buf->n_items == 0) {
        fprintf(stream, "(No data do print)\n");
        return;
    }

    for (size_t i = 0; i < buf->n_items; i++) {
        switch (buf->data[i]) {
        case '\n':
            fprintf(stream, "\\n\n");
            break;
        case '\t':
            fprintf(stream, "\\t");
            break;
        case '\r':
            fprintf(stream, "\\r");
            break;
        default:
            putc(buf->data[i], stream);
            break;
        }
    }
}
]])

   local fns = {}
   ctx.fns = fns
   ctx.file = "main.c"

   local tree = lib.ts_parser_parse_string(parser, nil, ctx.src, #ctx.src)
   local root = lib.ts_tree_root_node(tree)
   fill_scope(ctx, root)

   make_nodes(ctx, root)
   --print(inspect(ctx))
   return ctx.fns

   -- return {
   --    {
   --       id = 1,
   --       file = "main.lua",
   --       text_string =
   --          "function love.update(dt)\n" ..
   --          "   print(\"Hello!\")\n" ..
   --          "   timers.update(dt)\n" ..
   --          "   controls.update()\n" ..
   --          "end\n",

   --       --text_table = {...},
   --       line_count = 5,
   --       connections = {
   --          {line=3, char=20, fn_id=2},
   --          {line=4, char=20, fn_id=3},
   --       },
   --    },
      
   --    -- timers.update()
   --    {
   --       id = 2,
   --       file = "timers.lua",
   --       text_string =
   --          "function timers.update(dt)\n" ..
   --          "   global_timer = global_timer + dt\n"..
   --          "end\n",
   --       line_count = 3,
   --       connections = {},
   --    },
      
   --    -- controls.update()
   --    {
   --       id = 3,
   --       file = "controls.lua",
   --       text_string =
   --          "function controls.update()\n" ..
   --          "   whatever.dothing()\n" ..
   --          "end\n",
   --       line_count = 3,
   --       connections = {},
   --    }
   -- }
end
