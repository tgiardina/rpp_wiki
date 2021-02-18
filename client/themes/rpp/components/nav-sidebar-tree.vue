<template lang="pug">
    v-container
      v-treeview(open-on-click, :items="items", :open.sync='open', :expand-icon='""')
        template(v-slot:prepend="{ item, open }")
          v-icon(v-if="item.isFolder && open") mdi-folder-open
          v-icon(v-else-if="item.isFolder") mdi-folder    
          v-icon(v-else, @click='goTo(item)') mdi-text-box
        template(v-slot:label="{ item }")
          span(v-if="item.isFolder") {{item.title}}
          span(v-else, @click='goTo(item)') {{item.title}}        
</template>

<script>
  import _ from 'lodash'
  import gql from 'graphql-tag'
  import { get } from 'vuex-pathify'  

  const treeify = (item) => {
    item.name = item.title;
    if(item.isFolder) item.children = item.children || [];
  }

  export default {
    data: () => ({
      items: [],
      open: [],
    }),
    computed: {
      locale: get('page/locale')
    },      
    methods: {
      async getChildren(id) {
        const resp = await this.$apollo.query({
          query: gql`
            query ($parent: Int, $locale: String!) {
              pages {
                tree(parent: $parent, mode: ALL, locale: $locale) {
                  id
                  path
                  title
                  isFolder
                  pageId
                  parent
                  locale
                }
              }
            }
          `,
          fetchPolicy: 'cache-first',
          variables: {
            parent: id,
            locale: this.locale,
          }
        })             
        const items = _.get(resp, 'data.pages.tree', []);
        treeify(items);
        return items;
      },
      goTo(item) {
        window.location.href = `/${item.path}`
      },
      async load() {
        const items = await this.getChildren()
        this.items = _.cloneDeep(items) // Makes it look like sidebar loads quicker.
        const roots = [...items];
        while(items.length) {
          const item = items.pop()
          treeify(item);
          const children = await this.getChildren(item.id)
          item.children = children;
          items.push(...children);
        }
        while(this.items.length) this.items.pop();
        this.items.push(...roots);   
      },      
      preopenFolders() {
        const path = window.location.pathname.substring(1);
        if(!path.length) return;
        let items = [...this.items];
        while(items.length) {
          const item = items.pop();
          if(_.startsWith(path, item.path)) {
            if(!item.isFolder) return;
            this.open.push(item.id)
            items = [...item.children]
          }
        }
        throw new Error("Sidebar couldn't find current page")
      },      
    },    
    async mounted () {
      await this.load()
      this.preopenFolders()
    },    
  }
</script>
