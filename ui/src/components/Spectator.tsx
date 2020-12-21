import React from "react";

import './Spectator.scss';

interface Props {
    spectating: boolean;
    spectatorTarget: string;
}

const Spectator: React.FC<Props> = ({ spectating, spectatorTarget }) => {
    return (
        <>
            {(spectating === true) &&
                <div id="pageSpectator" className="page">
                    <div className={"infoBox notReady"}>
                        <h1>{spectatorTarget??''}</h1>
                        <h3>Spectating - Press SPACE to select the next teammate</h3>
                    </div>
                </div>
            }
        </>
    );
};

export default Spectator;
