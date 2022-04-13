This PR revives the functionality of a previously high-usage app - @LukiLeu's live traffic. As you'll recall, the cost of serving Google's Maps API proved to be unsustainable and it was subsequently removed from the app library after receiving hundreds of installs. This alternative app provides a familiar display with two new sources of data, and users will need to bring their own API keys in order to keep license usage low.

- **MapQuest**: provides real time directions for driving, cycling and walking, influenced by their traffic data
- **OpenRouteService**: provides "ideal" travel times that do not reflect traffic for a broader array of travel modes: e-bikes, wheelchairs, freight and hiking.

Also, since I'm unable to test the location selection tool from my local Pixlet emulator, I would very much appreciate some scrutiny from the Tidbyt team to ensure everything works as expected!

Finally, given the sensitivity around this app and the history around [its predecessor](https://github.com/tidbyt/community/pull/228), I am happy to discuss or revise as you/the community see fit. I am also willing to wait for LukiLeu's blessing as the author of its inspiration if you feel that would be appropriate!

## Key Features

![image](https://user-images.githubusercontent.com/7003930/162509305-db695115-b379-46f7-a7fb-6f0ed98bcdd6.png)

Like the previous app, we use `schema.Location` to set an Origin and Destination with optional labels. If the user doesn't provide labels, we will reverse-query the coordinates to get the nearest address. The API employed by each transportation mode is noted in the selection so users know which key(s) they need to use the app:

![image](https://user-images.githubusercontent.com/7003930/162509884-88903c78-1f5b-4cd6-9fe7-d717b2d4e437.png)

One key enhancement over the previous app is relative-duration color-coding. MapQuest's API provides both a "real time" and an "ideal" travel time when querying for directions, allowing us to calculate how much longer the current travel prediction is than it would be in a vacuum. We use this information to display times in green/yellow/red based on how much longer your trip may take - this proves to be a great way to monitor peak commute times and helps Tidbyt owners decide to leave earlier/later to save time! (See above vs. below)

We also are afforded a number of route configurations with MapQuest: we can tell the API that we prefer non-toll roads, or to avoid limited access roads like highways. These will all serve to make our trip duration more accurate if users know their commute well:

![image](https://user-images.githubusercontent.com/7003930/162509249-44d1801d-96da-4c5c-8d1e-f2431a549379.png)

Since we don't receive traffic information from ORS, we'll simply display times for those transportation methods in white:

![image](https://user-images.githubusercontent.com/7003930/162509668-28545466-3977-4b45-bfed-9ae0849bf539.png)

It's worth noting that this app is written to support the extension back to Google Maps if user demand justifies its inclusion, though with 15,000 monthly requests on the free MapQuest plan and having observed reasonable accuracy, I don't personally see the need to migrate!

The one major downside to MapQuest/ORS - no public transportation support! Though with the numerous train schedule apps on the platform already, I don't see this as a blocker to adoption.

## API Key Acquisition

I included the registration URL in the description of the schema, though I'd love to hear if there is a better way to offer instructions to app users. In both cases it is easy (and free!) to register for API keys:

### [MapQuest Profile, Manage Keys](https://developer.mapquest.com/user/me/apps)
![image](https://user-images.githubusercontent.com/7003930/162514682-95d66789-323e-41c9-9e37-1bdd35338708.png)
### [OpenRouteService Developer Dashboard](https://openrouteservice.org/dev/#/home)
![image](https://user-images.githubusercontent.com/7003930/162515344-c05d5aae-90b3-4fc4-b70b-0a1e38a92090.png)

