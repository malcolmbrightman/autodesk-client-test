<template>
  <ul class="tree-view-list">
    <li v-for="item in data" :key="item.id"
        class="tree-view-item"
        :class="{ 'selected': item.id === selectedItemId }">
        <!-- Click handler moved from li to this div -->

      <div class="item-content"
           :class="{ 'folder-item': item.type === 'folders', 'file-item': item.type !== 'folders' }"
           @click.stop="selectItem(item)"> <!-- Use .stop to prevent event bubbling -->
        <button v-if="item.type === 'folders'" @click.stop="handleToggle(item)" class="toggle-button"> <!-- Stop propagation on button too -->
          {{ getItemIcon(item) }}
        </button>
        <span v-else class="item-icon">{{ getItemIcon(item) }}</span>

        <span class="item-name">{{ item.attributes?.displayName }}</span>

        <span v-if="item.type === 'folders' && loadingFolders[item.id]" class="loading-indicator"> Loading...</span>
        <span v-if="item.type === 'folders' && errors[item.id]" class="error-indicator"> Error</span>
      </div>

      <!-- Recursive TreeView for expanded folders -->
      <TreeView
        v-if="item.type === 'folders' && expanded[item.id] && folderContents[item.id]?.data"
        :data="folderContents[item.id].data"
        :access-token="accessToken"
        :hub-id="hubId"
        :project-id="projectId"
        :selected-item-id="selectedItemId"
        @item-selected="bubbleSelectItem"
      />
    </li>
  </ul>
</template>

<script setup>
import { ref } from 'vue';
import axios from 'axios';

// Define props
const props = defineProps({
  data: { type: Array, required: true },
  accessToken: { type: String, required: true },
  hubId: { type: String, required: true },
  projectId: { type: String, required: true },
  selectedItemId: { type: String, default: null }
});

// Define emits
const emit = defineEmits(['item-selected']);

// Reactive state
const expanded = ref({});
const folderContents = ref({});
const loadingFolders = ref({});
const errors = ref({});

// Method to handle item selection
const selectItem = (item) => {
  // console.log('>>> selectItem function entered'); // Removed debug log
  // console.log('Item clicked:', item.attributes?.displayName, item.id); // Removed debug log
  emit('item-selected', item);
};

// Method to bubble up the event from nested TreeView components
const bubbleSelectItem = (item) => {
  emit('item-selected', item);
};


// Method to toggle folder expansion and fetch contents
const handleToggle = async (item) => {
  const id = item.id;
  if (!id || typeof id !== 'string') {
      console.error('Invalid item ID for toggle:', item);
      errors.value = { ...errors.value, [id || 'unknown']: 'Invalid item ID' };
      return;
  }
  expanded.value = { ...expanded.value, [id]: !expanded.value[id] };
  if (expanded.value[id] && !folderContents.value[id] && !loadingFolders.value[id]) {
    loadingFolders.value = { ...loadingFolders.value, [id]: true };
    errors.value = { ...errors.value, [id]: null };
    try {
      const contentsUrl = `https://developer.api.autodesk.com/data/v1/projects/${props.projectId}/folders/${id}/contents`;
      const contentsResponse = await axios.get(contentsUrl, {
        headers: { Authorization: `Bearer ${props.accessToken}` }
      });
      if (contentsResponse.status !== 200) throw new Error(`Server responded with status ${contentsResponse.status}`);
      if (!contentsResponse.data || !Array.isArray(contentsResponse.data.data)) {
          console.warn('Unexpected folder content structure:', contentsResponse.data);
          folderContents.value = { ...folderContents.value, [id]: { data: [] } };
      } else {
          folderContents.value = { ...folderContents.value, [id]: contentsResponse.data };
      }
    } catch (error) {
      const errorMessage = error.response?.data?.message || error.message || 'Failed to fetch folder contents';
      errors.value = { ...errors.value, [id]: errorMessage };
      console.error(`Failed to fetch folder contents for ${id}`, error);
    } finally {
      loadingFolders.value = { ...loadingFolders.value, [id]: false };
    }
  }
};

// Method to get the appropriate icon
const getItemIcon = (item) => {
  if (item.type === 'folders') {
    // Use > for collapsed, v for expanded for a more common tree view look
    return expanded.value[item.id] ? '▼' : '▶';
  } else {
    // Simple file icon
    return '📄';
  }
};

</script>

<style scoped>
/* Use variables defined in App.vue's global style or replicate values */
:root {
  --primary-color-selection: #cce5ff; /* Light blue for selection */
  --hover-bg-color: #e9ecef; /* Light gray for hover */
  --text-color: #212529;
  --error-color: #dc3545;
  --border-radius: 0.25rem;
}

.tree-view-list {
  list-style: none;
  padding-left: 1rem; /* Indentation for nested lists */
  margin: 0;
}

.tree-view-item {
  /* Container for the item content and its potential children list */
  padding: 0.1rem 0; /* Minimal vertical padding */
}

.item-content {
  display: flex;
  align-items: center;
  padding: 0.25rem 0.5rem; /* Padding inside the clickable area */
  border-radius: var(--border-radius, 0.25rem);
  cursor: pointer;
  transition: background-color 0.15s ease-in-out;
  white-space: nowrap; /* Prevent item name wrapping */
  overflow: hidden; /* Hide overflow */
  text-overflow: ellipsis; /* Add ellipsis if name is too long */
}

.tree-view-item:hover > .item-content {
  background-color: var(--hover-bg-color, #e9ecef);
}

.tree-view-item.selected > .item-content {
  background-color: var(--primary-color-selection, #cce5ff);
  font-weight: 500; /* Slightly bolder */
}

.toggle-button {
  margin-right: 0.3rem;
  background: none;
  border: none;
  cursor: pointer;
  font-size: 0.8em; /* Smaller icon */
  padding: 0 0.2rem;
  color: #6c757d; /* Dimmer color for toggle icon */
  line-height: 1; /* Ensure consistent height */
  width: 1em; /* Fixed width for alignment */
  text-align: center;
}

.toggle-button:focus {
  outline: none;
}

.item-icon {
  margin-right: 0.4rem;
  display: inline-block;
  width: 1em; /* Align with button width */
  text-align: center;
  color: #6c757d; /* Dimmer color for file icon */
  font-size: 0.9em;
}


.item-name {
  flex-grow: 1; /* Allow name to take available space */
  overflow: hidden;
  text-overflow: ellipsis;
}

.loading-indicator, .error-indicator {
  margin-left: 0.5rem;
  font-style: italic;
  font-size: 0.85em;
  color: #6c757d;
}

.error-indicator {
  color: var(--error-color, #dc3545);
  font-weight: bold;
}
</style>