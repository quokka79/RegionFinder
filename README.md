# RegionFinder

First Time Installation

Run the .mlappinstall file and MATLAB will open and ask you if you want to add RegionFinder to your Apps toolbar. Select 'Install'.
You can now run RegionFinder from the Apps toolbar

Upgrading RegionFinder

Uninstall the old version before you install the new one from here, otherwise you will have two RegionFinders installed. Open MATLAB, find the RegionFinder icon in your Apps toolbar. Right-click it and select 'Uninstall'. When finished, you can then proceed with installation of the newer version.

Usage

You'll need data freshly excreted from ThunderSTORM or from a Leica LAS-AF via SR GSD (as the ASCII data table). You can open any other text-based file as long asyou know how it's laid out and which columns hold your xy data. At the bare minimum you will need a text file with x and y coordinates in columns. If you have multiple data tables, it is a good idea to copy or move them to one place; when loading a folder Matlab will sort the files in the same way as your operating system (e.g. a natural-order sorting) thanks to the sort_nat.m script.

- In the first box, set the parameters to describe your data and the kind of regions you want to draw. Check that these are correct.
- In the second box, browse to your data file and open it. The software will load up to the first 30,000 points – you should be able to see your cell and major structures with this many points; any more and MATLAB will become sluggish in the following steps.
- For two channel data only 15,000 frames from each channel will be displayed.
- For three channel data only the first 10,000 frames from each channel will be displayed.
- In the third box, type some quick notes about this cell, for your reference later. These notes will be copied to the first column of your coords file later on.
- Click the Add Region button. Drag the region marker to wherever you wish (within reason … you can drag it outside the plot boundaries but that won't be very helpful to you). When you are satisfied, double-click within the region square and marvel as it is added to the list of regions on the left. Continue in this manner, clicking Add Region etc, for each region you wish. When you are done with that image, you may wish to click the Save PNG button to save a snapshot of your cell with the regions marked out on it.
- You may then load another data table and select regions for that image. They will be saved as originating from 'Table 2'. When you have selected regions in all of your cells, click the Export Regions button to save the list of regions as a formatted text file. This file is ready to use in the Cluster Analysis script.
- If you make a boo-boo and want to start again, click the Clear All button to begin again from scratch. If you open the wrong data table by accident you can manually correct the Data Table ID field – first load your correct data table, and the edit the number next to Data Table ID to it's correct value – usually one less than what it says, unless you opened a lot of different tables by mistake, in which case it is perhaps time to go home.
- You can also select a region and delete it from your list. If it is from the currently displayed data table, the corresponding rectangle will be deleted from the preview display also.
